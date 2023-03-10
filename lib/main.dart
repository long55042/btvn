// main.dart
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
      title: 'Bài kiểm  tra 1',
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
  final TextEditingController _masvController = TextEditingController();
  final TextEditingController _ngaysinhController = TextEditingController();
  final TextEditingController _gioitinhController = TextEditingController();
  final TextEditingController _quequanController = TextEditingController();

  final CollectionReference _sinhvien =
  FirebaseFirestore.instance.collection('sinhvien');

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _masvController.text = documentSnapshot['masv'];
      _ngaysinhController.text = documentSnapshot['ngaysinh'].toString();
      _gioitinhController.text = documentSnapshot['masv'];
      _quequanController.text = documentSnapshot['quequan'];
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
                  controller: _masvController,
                  decoration: const InputDecoration(labelText: 'Masv'),
                ),
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _ngaysinhController,
                  decoration: const InputDecoration(
                    labelText: 'Ngaysinh',
                  ),
                ),
                TextField(
                  controller: _gioitinhController,
                  decoration: const InputDecoration(labelText: 'gioi tinh'),
                ),
                TextField(
                  controller: _quequanController,
                  decoration: const InputDecoration(labelText: 'que quan'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? masv = _masvController.text;
                    final String? gioitinh = _gioitinhController.text;
                    final String? quequan = _quequanController.text;
                    final double? ngaysinh =
                    double.tryParse(_ngaysinhController.text);
                    if (masv != null && gioitinh != null && quequan != null && ngaysinh != null) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _sinhvien.add({"masv": masv, "gioitinh": gioitinh, "ngaysinh": ngaysinh, "quequan": quequan});
                      }

                      if (action == 'update') {
                        // Update the product
                        await _sinhvien
                            .doc(documentSnapshot!.id)
                            .update({"masv": masv, "gioitinh": gioitinh, "ngaysinh": ngaysinh, "quequan": quequan});
                      }

                      // Clear the text fields
                      _masvController.text = '';
                      _ngaysinhController.text = '';
                      _gioitinhController.text = '';
                      _quequanController.text = '';

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
  Future<void> _deleteProduct(String sinhvienId) async {
    await _sinhvien.doc(sinhvienId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a class')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bai kiem tra de so 1'),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: _sinhvien.snapshots(),
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
                    title: Container(
                        child: Column(
                          children: [
                            Text(documentSnapshot['masv']),
                            Text(documentSnapshot['gioitinh']),
                            Text(documentSnapshot['ngaysinh'].toString()),
                            Text(documentSnapshot['quequan']),
                          ],
                        ),),
                    // subtitle: Text(documentSnapshot['ngaysinh'].toString()),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // Press this button to edit a single product
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _createOrUpdate(documentSnapshot)),
                          IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _deleteProduct(documentSnapshot.id)),
                        ],
                          // This icon button is used to delete a single product
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
