import Capacitor
import Foundation

// var mockedData = [
//     1: [
//         "id": 1,
//         "name": "Interview with Ionic",
//         "dueDate": 1_634_569_785_944,
//         "done": true,
//     ],
//     2: [
//         "id": 2,
//         "name": "Create amazing product",
//         "dueDate": 1_634_569_785_944,
//         "done": false,
//     ],
//     3: [
//         "id": 3,
//         "name": "???",
//         "dueDate": 1_634_569_785_944,
//         "done": false,
//     ],
//     4: [
//         "id": 4,
//         "name": "Profit",
//         "dueDate": 1_634_569_785_944,
//         "done": false,
//     ],
// ]

@objc(ToDoPlugin)
public class ToDoPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ToDoPlugin"
    public let jsName = "ToDo"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getAll", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getOne", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "upsert", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "delete", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearAll", returnType: CAPPluginReturnPromise),
    ]

    private let storageKey = "ToDoItems"
    private var _toDoStored: [Int: ToDoItem]? = nil

    // lazy loading from UserDefaults
    // ensures data is only loaded when needed
    private var toDoStored: [Int: ToDoItem] {
        get {
            if _toDoStored == nil {
                _toDoStored = loadFromUserDefaults()
            }
            return _toDoStored ?? [:]
        }
        set {
            _toDoStored = newValue
        }
    }

    @objc func getAll(_ call: CAPPluginCall) {
        let todos = toDoStored.sorted { $0.key < $1.key }.map { $0.value.toDictionary() }
        call.resolve(["todos": todos])
    }

    @objc func getOne(_ call: CAPPluginCall) {
        guard let id = call.getInt("id"), let todo = toDoStored[id] else {
            call.reject("Malformed request, missing option id")
            return
        }
        call.resolve(["todo": todo.toDictionary()])
    }

    @objc func upsert(_ call: CAPPluginCall) {
        guard let name = call.getString("name"), let dueDate = call.getDouble("dueDate"), let done = call.getBool("done") else {
            call.reject("Malformed request, can't upsert")
            return
        }

        // in case of a new ToDo -> generateUniqueID()
        // in case of an existing id -> update the current call.getInt("id")
        let id = call.getInt("id") ?? generateUniqueID()
        toDoStored[id] = ToDoItem(id: id, name: name, dueDate: dueDate, done: done)
        saveToDosToUserDefaults()
        let todos = toDoStored.sorted { $0.key < $1.key }.map { $0.value.toDictionary() } // order and convert to dictionary
        call.resolve(["upsert": "ToDo with id \(id) updated/added!", "todos": todos]) // return new data to JS
    }

    @objc func delete(_ call: CAPPluginCall) {
        guard let id = call.getInt("id") else {
            call.reject("Malformed request, missing option id")
            return
        }

        guard toDoStored.keys.contains(id) else {
            call.reject("ToDo with id \(id) not found!")
            return
        }

        toDoStored.removeValue(forKey: id)
        saveToDosToUserDefaults()
        let todos = toDoStored.sorted { $0.key < $1.key }.map { $0.value.toDictionary() } // order and convert to dictionary
        call.resolve(["eliminated": "ToDo with id \(id) eliminated!", "todos": todos]) // return new data to JS
    }

    @objc func clearAll(_ call: CAPPluginCall) {
        toDoStored.removeAll()
        saveToDosToUserDefaults()
        call.resolve(["eliminated": "All ToDos deleted!", "todos": []]) // return new data to JS
    }

    // generate a new id starting from the current max id in the ToDo List
    // ensure the generated id is unique
    private func generateUniqueID() -> Int {
        var id = (toDoStored.keys.max() ?? 0) + 1
        while toDoStored.keys.contains(id) {
            id += 1
        }
        return id
    }

    private func saveToDosToUserDefaults() {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(toDoStored)
            UserDefaults.standard.set(encoded, forKey: storageKey)
        } catch {
            print("🔴 Failed to encode ToDo data: \(error.localizedDescription)")
        }
    }

    private func loadFromUserDefaults() -> [Int: ToDoItem] {
        let decoder = JSONDecoder()

        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoded = try decoder.decode([Int: ToDoItem].self, from: data)
                return decoded
            } catch {
                print("🔴 Failed to decode ToDo data from UserDefaults: \(error.localizedDescription)")
            }
        } else {
            print("No data found in UserDefaults for the key \(storageKey).")
        }

        let mockedData: [Int: ToDoItem] = [
            1: ToDoItem(id: 1, name: "Interview with Ionic", dueDate: 1_634_569_785_944, done: true),
            2: ToDoItem(id: 2, name: "Create amazing product", dueDate: 1_634_569_785_944, done: false),
            3: ToDoItem(id: 3, name: "???", dueDate: 1_634_569_785_944, done: false),
            4: ToDoItem(id: 4, name: "Profit", dueDate: 1_634_569_785_944, done: false),
        ]
        return mockedData
    }
}
