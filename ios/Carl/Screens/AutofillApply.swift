import SwiftUI
import WebKit

/// Carl's reliability edge over "auto-apply" tools: instead of a bot silently
/// failing to submit, Carl opens the real employer page **in-app**, autofills
/// the basics (name, email, phone), gives you your cover note + answers to drop
/// in, and YOU tap the employer's Submit. A credit is spent only when you then
/// confirm it went out — so you never pay for an application that didn't send.
struct AutofillApplyView: View {
    let item: QueueItem
    var onSubmitted: () -> Void = {}
    @Environment(CarlStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var copiedNote = false

    private var coverNote: String { store.draftEdits[item.matchId] ?? item.draft.coverNote }
    private var url: URL? { item.applyUrl.flatMap { URL(string: $0) } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // What Carl filled + the materials you may need to paste.
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 9) {
                        CarlMark(eyes: .happy).frame(width: 24, height: 23)
                        Text("Carl tries to fill your name, email & phone — double-check them, paste your cover note, then tap the page's Submit.")
                            .carl(12.5, .semibold).foregroundStyle(CarlColor.navy)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button {
                        UIPasteboard.general.string = coverNote
                        copiedNote = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copiedNote ? "checkmark" : "doc.on.doc").font(.system(size: 12, weight: .bold))
                            Text(copiedNote ? "Cover note copied" : "Copy cover note").carl(12.5, .bold)
                        }
                        .foregroundStyle(.white).padding(.horizontal, 12).frame(height: 32)
                        .background(CarlColor.royal, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(CarlColor.tintFill)

                if let url {
                    AutofillWebView(url: url, js: Self.autofillJS(store))
                } else {
                    Spacer()
                    Text("No application link for this role.").carl(14, .medium).foregroundStyle(CarlColor.textSoft)
                    Spacer()
                }
            }
            .navigationTitle(item.company)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                Button { onSubmitted() } label: {
                    CarlButton(title: "I submitted this application", systemIcon: "checkmark.circle.fill",
                               trailingNote: item.tailored == true ? "· 2 credits" : "· 1 credit")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }

    /// Build the injected autofill script with the user's details (semantic
    /// field matching — works across most ATS forms without per-site selectors).
    private static func autofillJS(_ store: CarlStore) -> String {
        let name = store.contact.name
        let parts = name.split(separator: " ").map(String.init)
        let first = parts.first ?? ""
        let last = parts.count > 1 ? parts.dropFirst().joined(separator: " ") : ""
        let data = "{email:\(js(store.contact.email)),phone:\(js(store.contact.phone))," +
            "firstName:\(js(first)),lastName:\(js(last)),fullName:\(js(name))}"
        return """
        (function(){
          var data = \(data);
          // React/Vue controlled inputs ignore a plain el.value=; use the native
          // setter then fire input/change so the framework registers the value.
          function nativeSet(el,val){
            if(!el||!val) return;
            try{
              var proto = el.tagName==='TEXTAREA' ? window.HTMLTextAreaElement.prototype : window.HTMLInputElement.prototype;
              var setter = Object.getOwnPropertyDescriptor(proto,'value').set;
              setter.call(el,val);
            }catch(e){ try{ el.value=val; }catch(_){} }
            try{
              el.dispatchEvent(new Event('input',{bubbles:true}));
              el.dispatchEvent(new Event('change',{bubbles:true}));
              el.dispatchEvent(new Event('blur',{bubbles:true}));
            }catch(e){}
          }
          function hay(el){
            var lbl='';
            try{ if(el.labels&&el.labels.length){ lbl=el.labels[0].innerText||el.labels[0].textContent||''; } }catch(e){}
            return ((el.name||'')+' '+(el.id||'')+' '+(el.placeholder||'')+' '+(el.getAttribute('aria-label')||'')+' '+lbl).toLowerCase();
          }
          function has(el,keys){ var h=hay(el); return keys.some(function(k){return h.indexOf(k)>=0;}); }
          function fillDoc(doc){
            var n=0;
            var els = Array.prototype.slice.call(doc.querySelectorAll('input,textarea'));
            els.forEach(function(el){
              if(el.type==='hidden'||el.disabled||el.readOnly) return;
              if(el.value) return; // don't clobber anything already there
              if(el.type==='email'||has(el,['email','e-mail'])) { nativeSet(el,data.email); n++; }
              else if(has(el,['first name','firstname','first_name','given'])) { nativeSet(el,data.firstName); n++; }
              else if(has(el,['last name','lastname','last_name','surname','family'])) { nativeSet(el,data.lastName); n++; }
              else if(has(el,['full name','full_name','your name'])||(el.name||'').toLowerCase()==='name') { nativeSet(el,data.fullName); n++; }
              else if(el.type==='tel'||has(el,['phone','mobile','tel'])) { nativeSet(el,data.phone); n++; }
            });
            // Reach into same-origin iframes (some ATS embed the form this way).
            var frames = doc.querySelectorAll('iframe');
            for(var i=0;i<frames.length;i++){ try{ var d=frames[i].contentDocument; if(d) n+=fillDoc(d); }catch(e){} }
            return n;
          }
          // Forms often render after load; poll for a few seconds.
          var tries=0;
          var iv=setInterval(function(){ tries++; fillDoc(document); if(tries>=15) clearInterval(iv); },400);
        })();
        """
    }

    private static func js(_ s: String) -> String {
        let e = s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")
        return "\"\(e)\""
    }
}

/// Minimal WKWebView wrapper that runs an autofill script once the page loads.
struct AutofillWebView: UIViewRepresentable {
    let url: URL
    let js: String

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.navigationDelegate = context.coordinator
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(js: js) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let js: String
        init(js: String) { self.js = js }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
