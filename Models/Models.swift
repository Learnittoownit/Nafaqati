import Foundation

// ─── PARENT ───────────────────────────────
struct Parent: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String
    var phone: String?
    var defaultSavePercent: Int
    var defaultSpendPercent: Int
    var defaultGivePercent: Int
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case defaultSavePercent  = "default_save_percent"
        case defaultSpendPercent = "default_spend_percent"
        case defaultGivePercent  = "default_give_percent"
        case createdAt           = "created_at"
    }
}

// ─── CHILD PROFILE ────────────────────────
struct ChildProfile: Codable, Identifiable {
    let id: UUID
    var parentId: UUID
    var name: String
    var age: Int
    var avatarUrl: String?
    var pin: String?
    var pinResetRequired: Bool
    var inviteCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case parentId         = "parent_id"
        case name
        case age
        case avatarUrl        = "avatar_url"
        case pin
        case pinResetRequired = "pin_reset_required"
        case inviteCode       = "invite_code"
    }
}
// ─── JAR ──────────────────────────────────
struct Jar: Codable, Identifiable {
    let id: UUID
    var childId: UUID
    var type: JarType
    var balance: Double
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case childId   = "child_id"
        case type
        case balance
        case updatedAt = "updated_at"
    }
}

enum JarType: String, Codable {
    case saving   = "saving"
    case spending = "spending"
    case giving   = "giving"

    var displayName: String {
        switch self {
        case .saving:  return "Saving"
        case .spending: return "Spending"
        case .giving:  return "Giving"
        }
    }

    var color: String {
        switch self {
        case .saving:   return "yellow"
        case .spending: return "red"
        case .giving:   return "green"
        }
    }
}

// ─── GOAL ─────────────────────────────────
struct Goal: Codable, Identifiable, Equatable {
    var id:         UUID   = UUID()
    var childId:    UUID?  = nil
    var jarId:      UUID?  = nil
    var isAchieved: Bool   = false
    var deadline:   Date?  = nil
    var createdAt:  Date?  = nil
    var name:       String
    var icon:       String = "🎯"
    var target:     Double
    var saved:      Double = 0
    var days:       Int    = 30
    var status:     String = "pending"

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(saved / target, 1.0)
    }
    var percent: Int { Int(progress * 100) }
    var remainingAmount: Double { max(target - saved, 0) }

    enum CodingKeys: String, CodingKey {
        case id
        case childId    = "child_id"
        case jarId      = "jar_id"
        case name       = "title"
        case target     = "target_price"
        case saved      = "saved_amount"
        case deadline
        case isAchieved = "is_achieved"
        case createdAt  = "created_at"
        case icon
        case days
        case status
    }
}// ─── CHILD ACTIVITY ITEM ──────────────────
struct ChildActivityItem: Identifiable, Equatable, Codable {
    var id:        UUID   = UUID()
    var name:      String
    var timestamp: Date   = Date()
    var amount:    Double
    var jarColor:  String
    var sfSymbol:  String
}

// ─── ALLOWANCE ────────────────────────────
struct Allowance: Codable, Identifiable {
    let id: UUID
    var parentId: UUID
    var childId: UUID
    var amount: Double
    var savePercent: Int
    var spendPercent: Int
    var givePercent: Int
    var message: String?
    var voiceNoteUrl: String?
    var sentAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case parentId    = "parent_id"
        case childId     = "child_id"
        case amount
        case savePercent  = "save_percent"
        case spendPercent = "spend_percent"
        case givePercent  = "give_percent"
        case message
        case voiceNoteUrl = "voice_note_url"
        case sentAt       = "sent_at"
    }
}

// ─── EIDIYA ───────────────────────────────
struct Eidiya: Codable, Identifiable {
    let id: UUID
    var childId: UUID
    var giverName: String
    var amount: Double
    var receivedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case childId    = "child_id"
        case giverName  = "giver_name"
        case amount
        case receivedAt = "received_at"
    }
}

// ─── TRANSACTION ──────────────────────────
struct Transaction: Codable, Identifiable {
    let id: UUID
    var childId: UUID
    var jarId: UUID
    var type: TransactionType
    var amount: Double
    var source: TransactionSource
    var referenceId: UUID?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case childId     = "child_id"
        case jarId       = "jar_id"
        case type
        case amount
        case source
        case referenceId = "reference_id"
        case createdAt   = "created_at"
    }
}

enum TransactionType: String, Codable {
    case deposit    = "deposit"
    case withdrawal = "withdrawal"
    case transfer   = "transfer"
}

enum TransactionSource: String, Codable {
    case allowance = "allowance"
    case eidiya    = "eidiya"
    case manual    = "manual"
}

// ─── INVITE CODE ──────────────────────────
struct InviteCode: Codable, Identifiable {
    let id: UUID
    var childId: UUID
    var code: String
    var expiresAt: Date
    var isUsed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case childId   = "child_id"
        case code
        case expiresAt = "expires_at"
        case isUsed    = "is_used"
    }
}
