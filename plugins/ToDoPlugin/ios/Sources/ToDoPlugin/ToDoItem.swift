import Foundation

struct ToDoItem: Codable {
    let id: Int
    let name: String
    let dueDate: Double
    let done: Bool

    func toDictionary() -> [String: Any] { // to transform ToDoItem in a compatible format for JS
        return ["id": id, "name": name, "dueDate": dueDate, "done": done]
    }
}
