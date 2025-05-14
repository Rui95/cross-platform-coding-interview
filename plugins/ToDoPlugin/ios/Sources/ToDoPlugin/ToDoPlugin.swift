import Capacitor
import Foundation

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

    // Lazy loading from UserDefaults
    // On first access, tries to load saved data
    // If loading fails, return mocked data
    private var toDoStored: [Int: ToDoItem] {
        get {
            if _toDoStored == nil {
                switch loadFromUserDefaults() {
                case let .success(toDos):
                    _toDoStored = toDos
                case let .failure(error):
                    print(error.localizedDescription)
                    _toDoStored = mockedData()
                }
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
        let todos = toDoStored.sorted { $0.key < $1.key }.map { $0.value.toDictionary() }
        switch saveToDosToUserDefaults() {
        case .success:
            call.resolve(["upsert": "ToDo with id \(id) updated/inserted!", "todos": todos]) // return new data to JS
        case let .failure(error):
            call.reject("Failed to save ToDo", nil, error)
        }
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
        let todos = toDoStored.sorted { $0.key < $1.key }.map { $0.value.toDictionary() }
        switch saveToDosToUserDefaults() {
        case .success:
            call.resolve(["delete": "ToDo with id \(id) eliminated!", "todos": todos]) // return new data to JS
        case let .failure(error):
            call.reject("Failed to save ToDo", nil, error)
        }
    }

    @objc func clearAll(_ call: CAPPluginCall) {
        toDoStored.removeAll()
        switch saveToDosToUserDefaults() {
        case .success:
            call.resolve(["clearAll": "All ToDos deleted!", "todos": []]) // return new data to JS
        case let .failure(error):
            call.reject("Failed to save ToDo", nil, error)
        }
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

    private func saveToDosToUserDefaults() -> Result<Void, Error> {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(toDoStored)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func loadFromUserDefaults() -> Result<[Int: ToDoItem], Error> {
        let decoder = JSONDecoder()

        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoded = try decoder.decode([Int: ToDoItem].self, from: data)
                return .success(decoded)
            } catch {
                return .failure(error)
            }
        } else {
            let error = NSError(domain: "ToDoPlugin", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data found in UserDefaults for key '\(storageKey)'."])
            return .failure(error)
        }
    }

    private func mockedData() -> [Int: ToDoItem] {
        let mockedData: [Int: ToDoItem] = [
            1: ToDoItem(id: 1, name: "Interview with Ionic", dueDate: 1_634_569_785_944, done: true),
            2: ToDoItem(id: 2, name: "Create amazing product", dueDate: 1_634_569_785_944, done: false),
            3: ToDoItem(id: 3, name: "???", dueDate: 1_634_569_785_944, done: false),
            4: ToDoItem(id: 4, name: "Profit", dueDate: 1_634_569_785_944, done: false),
        ]
        return mockedData
    }
}
