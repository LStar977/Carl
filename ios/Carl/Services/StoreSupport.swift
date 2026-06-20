import SwiftUI

extension CarlColor {
    /// Maps a backend avatar-color name to a brand color.
    static func named(_ name: String) -> Color {
        switch name {
        case "greenhouse": return greenhouse
        case "lever": return lever
        case "ashby": return ashby
        case "royal": return royal
        default: return navy
        }
    }
}

extension JobMatch {
    init(dto: MatchDTO) {
        self.init(letter: dto.letter,
                  avatarColor: CarlColor.named(dto.avatarColor),
                  title: dto.title,
                  company: dto.company,
                  detail: dto.detail,
                  fit: dto.fit)
    }
}
