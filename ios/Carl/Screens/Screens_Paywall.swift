import SwiftUI

// MARK: - Paywall (selectable credit-pack stack)

struct PaywallScreen: View {
    var onPurchase: () -> Void = {}
    @Environment(CarlStore.self) private var store

    private func buy(_ packId: String) {
        Task { if await store.buy(packId: packId) { onPurchase() } }
    }

    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    CarlMark().frame(width: 62, height: 60)
                    Text("Put Carl to work").carl(24, .heavy).foregroundStyle(CarlColor.navy)
                    Text("Credits are applications. Carl applies — you just approve.")
                        .carl(14, .medium).foregroundStyle(CarlColor.textSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 14)

                HStack(spacing: 8) {
                    Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(.white)
                        .frame(width: 24, height: 24).background(CarlColor.green, in: Circle())
                    Text("Your first 3 applications are on me — free.")
                        .carl(13.5, .bold).foregroundStyle(CarlColor.greenDeep)
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(CarlColor.greenBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xC9ECD7), lineWidth: 1))
                .padding(.bottom, 16)

                VStack(spacing: 11) {
                    Button { buy("starter") } label: {
                        packRow(name: "Starter · 25", sub: "25 applications", price: "$19", each: "$0.76 each")
                    }.buttonStyle(.plain)
                    Button { buy("popular") } label: { featuredPackRow() }.buttonStyle(.plain)
                    Button { buy("pro") } label: {
                        packRowBonus(name: "Pro · 300", bonus: "+40 bonus", sub: "340 applications",
                                     price: "$149", each: "$0.44 each")
                    }.buttonStyle(.plain)
                }

                HStack(spacing: 7) {
                    Image(systemName: "info.circle").font(.system(size: 14)).foregroundStyle(CarlColor.royal)
                    (Text("Carl only spends a credit when he ").carl(12.5, .semibold).foregroundColor(CarlColor.textSoft)
                     + Text("actually submits").carl(12.5, .bold).foregroundColor(CarlColor.navy)
                     + Text(" — never for looking.").carl(12.5, .semibold).foregroundColor(CarlColor.textSoft))
                }
                .multilineTextAlignment(.center)
                .padding(.top, 14)

                Spacer()
                Button { buy("popular") } label: { CarlButton(title: "Get 110 credits — $59") }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                TrustRow(items: [("lock.fill", "Secure payment"), ("checkmark.shield.fill", "Cancel anytime"), ("checkmark", "No expiry")])
            }
            .padding(.horizontal, 22)
            .padding(.top, 74).padding(.bottom, 36)
            .overlay(alignment: .topTrailing) {
                Text("Restore").carl(14, .bold).foregroundStyle(CarlColor.royal)
                    .padding(.top, 62).padding(.trailing, 24)
            }
        }
    }

    private func packRow(name: String, sub: String, price: String, each: String) -> some View {
        HStack(spacing: 14) {
            Circle().strokeBorder(Color(hex: 0xC5CDDD), lineWidth: 2).frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).carl(18, .heavy).foregroundStyle(CarlColor.navy)
                Text(sub).carl(12.5, .semibold).foregroundStyle(CarlColor.textFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(price).carl(20, .heavy).foregroundStyle(CarlColor.navy)
                Text(each).carl(12, .semibold).foregroundStyle(CarlColor.textFaint)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(CarlColor.borderSoft, lineWidth: 1.5))
    }

    private func packRowBonus(name: String, bonus: String, sub: String, price: String, each: String) -> some View {
        HStack(spacing: 14) {
            Circle().strokeBorder(Color(hex: 0xC5CDDD), lineWidth: 2).frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name).carl(18, .heavy).foregroundStyle(CarlColor.navy)
                    Text(bonus).carl(12, .bold).foregroundStyle(CarlColor.royal)
                }
                Text(sub).carl(12.5, .semibold).foregroundStyle(CarlColor.textFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(price).carl(20, .heavy).foregroundStyle(CarlColor.navy)
                Text(each).carl(12, .semibold).foregroundStyle(CarlColor.textFaint)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(CarlColor.borderSoft, lineWidth: 1.5))
    }

    private func featuredPackRow() -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .heavy)).foregroundStyle(CarlColor.royal)
                .frame(width: 22, height: 22).background(.white, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Popular · 100").carl(19, .heavy).foregroundStyle(.white)
                    Text("+10 bonus").carl(12, .bold).foregroundStyle(CarlColor.gold)
                }
                Text("110 applications").carl(12.5, .semibold).foregroundStyle(CarlColor.textOnNavySoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("$59").carl(22, .heavy).foregroundStyle(.white)
                Text("$0.54 each").carl(12, .semibold).foregroundStyle(CarlColor.textOnNavySoft)
            }
        }
        .padding(18)
        .background(
            LinearGradient(colors: [CarlColor.royal, CarlColor.navy], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: CarlColor.royal.opacity(0.32), radius: 16, y: 14)
        .overlay(alignment: .top) {
            Text("★ BEST VALUE").carl(11, .heavy).foregroundStyle(CarlColor.navy)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(CarlColor.gold, in: Capsule())
                .offset(y: -11)
        }
    }
}

struct TrustRow: View {
    var items: [(String, String)]
    var tint: Color = CarlColor.textGhost
    var body: some View {
        HStack(spacing: 16) {
            ForEach(items, id: \.1) { item in
                HStack(spacing: 5) {
                    Image(systemName: item.0).font(.system(size: 11))
                    Text(item.1).carl(12, .semibold)
                }
                .foregroundStyle(tint)
            }
        }
    }
}

// MARK: - Buy more credits (sheet)

struct BuyMoreScreen: View {
    var body: some View {
        PhoneFrame(chrome: .light, homeIndicatorLight: true) {
            CarlColor.navy
        } content: {
            ZStack(alignment: .bottom) {
                // dimmed dashboard backdrop
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 8).fill(.white).frame(width: 180, height: 30)
                    RoundedRectangle(cornerRadius: 20).fill(.white).frame(height: 120)
                    RoundedRectangle(cornerRadius: 18).fill(.white).frame(height: 70)
                    RoundedRectangle(cornerRadius: 18).fill(.white).frame(height: 70)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 80)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(0.32)
                Color.black.opacity(0.45).ignoresSafeArea()

                // sheet
                VStack(spacing: 0) {
                    Capsule().fill(Color(hex: 0xCFD6E4)).frame(width: 42, height: 5).padding(.bottom, 20)
                    HStack(spacing: 12) {
                        CarlAvatar(showDashes: true, floats: false).frame(width: 48, height: 46)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Running low on credits").carl(20, .heavy).foregroundStyle(CarlColor.navy)
                            (Text("You've got ").carl(13.5, .medium).foregroundColor(CarlColor.textSoft)
                             + Text("8 left").carl(13.5, .bold).foregroundColor(CarlColor.red)
                             + Text(" — top up to keep Carl going.").carl(13.5, .medium).foregroundColor(CarlColor.textSoft))
                        }
                        Spacer()
                    }
                    .padding(.bottom, 18)

                    VStack(spacing: 11) {
                        topUpRow(title: "+25 credits", each: "$0.76 each", price: "$19", selected: false, bonus: nil)
                        topUpRow(title: "+110 credits", each: "$0.54 each", price: "$59", selected: true, bonus: "incl. 10 bonus")
                        topUpRow(title: "+340 credits", each: "$0.44 each", price: "$149", selected: false, bonus: "incl. 40 bonus")
                    }
                    .padding(.bottom, 18)

                    CarlButton(title: "Add 110 credits — $59").padding(.bottom, 12)
                    Text("Credits never expire · Carl only spends them on real submissions")
                        .carl(12.5, .semibold).foregroundStyle(CarlColor.textFaint)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 40)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous)
                        .fill(CarlColor.screenBG)
                )
                .shadow(color: .black.opacity(0.3), radius: 30, y: -20)
            }
        }
    }

    private func topUpRow(title: String, each: String, price: String, selected: Bool, bonus: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).carl(17, .heavy).foregroundStyle(CarlColor.navy)
                    if let bonus { Text(bonus).carl(12, .bold).foregroundStyle(selected ? CarlColor.royal : CarlColor.textFaint) }
                }
                Text(each).carl(12, .semibold).foregroundStyle(selected ? CarlColor.royal : CarlColor.textFaint)
            }
            Spacer()
            Text(price).carl(18, .heavy).foregroundStyle(CarlColor.navy)
        }
        .padding(.horizontal, 18).padding(.vertical, 15)
        .background(selected ? CarlColor.tintFill : CarlColor.card,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(selected ? CarlColor.royal : CarlColor.borderSoft, lineWidth: 1.5)
        )
        .overlay(alignment: .topTrailing) {
            if selected {
                Text("BEST VALUE").carl(10, .heavy).foregroundStyle(.white)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(CarlColor.royal, in: Capsule())
                    .offset(x: -16, y: -10)
            }
        }
    }
}
