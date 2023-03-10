import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      title: 'Bai kiem tra de so 4',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text fields' controllers
  final TextEditingController _maMonHocController = TextEditingController();
  final TextEditingController _tenMonHocController = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();
  final CollectionReference _monHoc =
  FirebaseFirestore.instance.collection('monHoc');

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _maMonHocController.text = documentSnapshot['maMonHoc'].toString();
      _tenMonHocController.text = documentSnapshot['tenMonHoc'];
      _moTaController.text = documentSnapshot['moTa'].toString();
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                // prevent the soft keyboard from covering text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _maMonHocController,
                  decoration: const InputDecoration(
                    labelText: 'Mã môn học',
                  ),
                ),
                TextField(
                  controller: _tenMonHocController,
                  decoration: const InputDecoration(labelText: 'Tên Môn Học'),
                ),
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _moTaController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? maMonHoc = _maMonHocController.text;
                    final String? tenMonHoc = _tenMonHocController.text;
                    final String? moTa = _moTaController.text;
                    if (maMonHoc != null && tenMonHoc != null && moTa != null) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _monHoc.add({"maMonHoc": maMonHoc, "tenMonHoc": tenMonHoc, "moTa": moTa});
                      }

                      if (action == 'update') {
                        // Update the product
                        await _monHoc
                            .doc(documentSnapshot!.id)
                            .update({"maMonHoc": maMonHoc, "tenMonHoc": tenMonHoc, "moTa": moTa});
                      }

                      // Clear the text fields
                      _maMonHocController.text = '';
                      _tenMonHocController.text = '';
                      _moTaController.text = '';
                      // Hide the bottom sheet
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  // Deleteing a product by id
  Future<void> _deleteProduct(String monHocId) async {
    await _monHoc.doc(monHocId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a class')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài Kiểm Tra Số 04'),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: _monHoc.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Container(child: Column(
                      children: [
                        Text(documentSnapshot['maMonHoc']),
                        SizedBox(
                          height: 5,
                        ),
                        Text(documentSnapshot['tenMonHoc']),
                      ],
                    )),
                    subtitle: Column(
                      children: [
                        Text(documentSnapshot['moTa'].toString()),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // Press this button to edit a single product
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _createOrUpdate(documentSnapshot)),
                          // This icon button is used to delete a single product
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteProduct(documentSnapshot.id)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // Add new product
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}