
import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    var messages : [Message] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        title = K.appName
        tableView.dataSource = self
        navigationItem.hidesBackButton = true
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadData()
    }
    
    func loadData() {
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { (querySnapshot, error) in
            if let e = error {
                print("Error retriving data \(e)")
            } else {
                self.messages = []
                if let snapshotDocuments = querySnapshot?.documents {
                    for snapshotDocument in snapshotDocuments {
                        if let messageSender = snapshotDocument.data()[K.FStore.senderField] as? String , let messageBody = snapshotDocument.data()[K.FStore.bodyField] as? String {
                             let message = Message(sender: messageSender, body: messageBody)
                            self.messages.append(message)
                            
                            DispatchQueue.main.async{
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let body = messageTextfield.text, let sender = Auth.auth().currentUser?.email {
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.bodyField : body,
                K.FStore.senderField : sender,
                K.FStore.dateField : Date().timeIntervalSince1970
            ], completion: { (error) in
                if let e = error {
                    print("Firebase error \(e)")
                } else {
                    print("Succesfuly saved data")
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                }
            })
        }
        
    }
    
    @IBAction func signOutButtonPressed(_ sender: UIBarButtonItem) {
        do {
          try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
}

extension ChatViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCellTableViewCell
        cell.label.text = messages[indexPath.row].body
        if messages[indexPath.row].sender != Auth.auth().currentUser?.email {
            cell.avatarImage.image = UIImage(named: "YouAvatar")
            cell.messageBubble.backgroundColor = #colorLiteral(red: 0, green: 0.6765418649, blue: 1, alpha: 1)
        }
        return cell
    }
    
    
}
