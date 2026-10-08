import Foundation
@main struct Oracle {
    @MainActor static func main() {
        let session = Session()
        while let line = readLine() { print(session.request(line)); fflush(stdout) }
    }
}
