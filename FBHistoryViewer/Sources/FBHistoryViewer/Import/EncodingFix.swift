import Foundation

extension String {
    /// Facebook's JSON export uses latin-1 byte values written into a UTF-8 string,
    /// producing mojibake for non-ASCII characters (e.g. Polish ą, ę, ó).
    /// This re-interprets the string bytes as latin-1 then decodes as UTF-8.
    var fixedFacebookEncoding: String {
        guard let latin1Data = self.data(using: .isoLatin1) else { return self }
        return String(data: latin1Data, encoding: .utf8) ?? self
    }
}

func fixOptional(_ s: String?) -> String? {
    s.map { $0.fixedFacebookEncoding }
}
