import Foundation

struct ProfileData {
    var name: String = ""
    var username: String = ""
    var aboutMe: String = ""
    var birthday: String = ""        // formatted, e.g. "April 18, 1977"
    var city: String = ""
    var hometown: String = ""
    var gender: String = ""
    var workExperiences: [WorkExperience] = []
    var educationExperiences: [EducationExperience] = []
    var websites: [String] = []
    var screenNames: [(service: String, name: String)] = []
    var familyMembers: [(name: String, relation: String)] = []
    var friendsCount: Int = 0
    var followersCount: Int = 0
    var profilePhotos: [ProfilePhoto] = []   // sorted newest first
}

struct WorkExperience: Identifiable {
    var id = UUID()
    var employer: String
    var title: String?
    var location: String?
    var period: String?   // e.g. "2017 – present" or "2010 – 2016"
}

struct EducationExperience: Identifiable {
    var id = UUID()
    var school: String
    var degree: String?
    var field: String?
    var schoolType: String?
}

struct ProfilePhoto: Identifiable {
    var id: Int64 { timestamp }
    var timestamp: Int64
    var imageURL: URL
    var date: Date { Date(timeIntervalSince1970: Double(timestamp)) }
}
