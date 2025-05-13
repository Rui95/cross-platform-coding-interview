import ToDoListItem from "../components/ToDoListItem";
import { createRef, useState } from "react";
import { ToDo, ToDoItem } from "capacitor-todo-plugin";
import {
  IonButton,
  IonContent,
  IonHeader,
  IonList,
  IonPage,
  IonRefresher,
  IonRefresherContent,
  IonTitle,
  IonToolbar,
  useIonViewWillEnter,
  IonAlert,
} from "@ionic/react";
import "./Home.css";

const Home: React.FC = () => {
  const [todos, setTodos] = useState<ToDoItem[]>([]);
  const ionListRef = createRef<HTMLIonListElement>();
  const [showAlert, setShowAlert] = useState(false);

  useIonViewWillEnter(() => {
    ToDo.getAll()
      .then(({ todos }) => {
        setTodos(todos);
      })
  });

  const refresh = async (e?: CustomEvent) => {
    ionListRef.current?.closeSlidingItems();
    const { todos } = await ToDo.getAll();
    setTodos(todos);
    e?.detail.complete();
  };

  const clearAll = async () => {
    const { todos = [] } = await ToDo.clearAll?.() ?? {}; //once is optional on interface
    setTodos(todos);
  };

  const handleClearAll = () => {
    setShowAlert(true)
  };

  return (
    <IonPage id="home-page">
      <IonHeader>
        <IonToolbar>
          <IonTitle>ToDos</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent fullscreen>
        <IonRefresher slot="fixed" onIonRefresh={refresh}>
          <IonRefresherContent></IonRefresherContent>
        </IonRefresher>

        <IonHeader collapse="condense">
          <IonToolbar>
            <IonTitle size="large">ToDos</IonTitle>
          </IonToolbar>
        </IonHeader>

        <IonList ref={ionListRef}>
          {todos.map((t) => (
            <ToDoListItem key={t.id} todo={t} refresh={refresh} />
          ))}
          <IonButton
            expand="block"
            onClick={() => (window.location.pathname = "/todo")}
          >
            Create ToDo
          </IonButton>
          {/* Show clear button if more than one ToDo  */}
          {todos.length > 1 && (
            <IonButton
              expand="block"
              color="danger"
              onClick={handleClearAll} // show alert before delete
            >
              Clear All
            </IonButton>
          )}

          <IonAlert isOpen={showAlert}
            onDidDismiss={() => setShowAlert(false)}
            header={'Delete all ToDos'}
            message={'Are you sure you want to delete all ToDos?'}
            buttons={[
              {
                text: 'Cancel',
                role: 'cancel',
                handler: () => console.log('Cancel delete all'),
              },
              {
                text: 'Delete All',
                handler: () => {
                  clearAll();
                  setShowAlert(false) //close alert
                },
              }
            ]} />
        </IonList>
      </IonContent>
    </IonPage>
  );
};

export default Home;
