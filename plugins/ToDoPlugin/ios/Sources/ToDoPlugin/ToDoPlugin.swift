import Capacitor
import Foundation

var mockedData = [
    1: [
        "id": 1,
        "name": "Interview with Ionic",
        "dueDate": 1_634_569_785_944,
        "done": true,
    ],
    2: [
        "id": 2,
        "name": "Create amazing product",
        "dueDate": 1_634_569_785_944,
        "done": false,
    ],
    3: [
        "id": 3,
        "name": "???",
        "dueDate": 1_634_569_785_944,
        "done": false,
    ],
    4: [
        "id": 4,
        "name": "Profit",
        "dueDate": 1_634_569_785_944,
        "done": false,
    ],
]

@objc(ToDoPlugin)
public class ToDoPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ToDoPlugin"
    public let jsName = "ToDo"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getAll", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getOne", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "upsert", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "delete", returnType: CAPPluginReturnPromise),
    ]

    @objc func getAll(_ call: CAPPluginCall) {
        let todos = mockedData.sorted { $0.key < $1.key }.map { $0.value }
        call.resolve(["todos": todos])
    }

    @objc func getOne(_ call: CAPPluginCall) {
        guard let id = call.getInt("id") else {
            call.reject("Malformed request, missing option id")
            return
        }
        call.resolve(["todo": mockedData[id] as Any])
    }

    @objc func upsert(_ call: CAPPluginCall) {
        print("🟢 upsert() called")

        guard let name = call.getString("name"),
              let dueDate = call.getDouble("dueDate"), let done = call.getBool("done")
        else {
            call.reject("Malformed request, can't upsert")
            return
        }

        // in case of a new ToDo -> get the max id from the ToDo list, and increment 1 for the next id in the ToDo
        // incase of an existing id -> update the current call.getInt("id")
        let id = call.getInt("id") ?? (mockedData.keys.max() ?? 0) + 1

        mockedData[id] = ["id": id, "name": name, "dueDate": dueDate, "done": done]
        let todos = mockedData.sorted { $0.key < $1.key }.map { $0.value }
        call.resolve(["upsert": "ToDo with id \(id) updated/added!", "todos": todos])
    }

    @objc func delete(_ call: CAPPluginCall) {
        print("🔴 delete() called")

        guard let id = call.getInt("id") else {
            call.reject("Malformed request, missing option id")
            return
        }

        guard mockedData.keys.contains(id) else {
            call.reject("ToDo with id \(id) not found!")
            return
        }

        mockedData.removeValue(forKey: id)
        let todos = mockedData.sorted { $0.key < $1.key }.map { $0.value }
        call.resolve(["eliminated": "ToDo with id \(id) eliminated!", "todos": todos])
    }
}
