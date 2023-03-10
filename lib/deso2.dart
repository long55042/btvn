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
      title: 'bai tap ve nha deso2',
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
  final TextEditingController _magiangvienController = TextEditingController();
  final TextEditingController _hotenController = TextEditingController();
  final TextEditingController _diachiController = TextEditingController();
  final TextEditingController _sdtController = TextEditingController();
  final CollectionReference _giangVien =
  FirebaseFirestore.instance.collection('giangVien');

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _magiangvienController.text = documentSnapshot['maGiangVien'].toString();
      _hotenController.text = documentSnapshot['hoTen'];
      _diachiController.text = documentSnapshot['diaChi'].toString();
      _sdtController.text = documentSnapshot['sdt'].toString();
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
                  controller: _magiangvienController,
                  decoration: const InputDecoration(
                    labelText: 'Mã Giảng Viên',
                  ),
                ),
                TextField(
                  controller: _hotenController,
                  decoration: const InputDecoration(labelText: 'Họ Tên'),
                ),
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _diachiController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                  ),
                ),
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _sdtController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? maGiangVien = _magiangvienController.text;
                    final String? hoTen = _hotenController.text;
                    final String? diaChi = _diachiController.text;
                    final String? sdt = _sdtController.text;
                    if (maGiangVien != null && hoTen != null && diaChi != null && sdt != null) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _giangVien.add({"maGiangVien": maGiangVien, "hoTen": hoTen, "diaChi": diaChi, "sdt": sdt});
                      }

                      if (action == 'update') {
                        // Update the product
                        await _giangVien
                            .doc(documentSnapshot!.id)
                            .update({"maGiangVien": maGiangVien, "hoTen": hoTen, "diaChi": diaChi, "sdt": sdt});
                      }

                      // Clear the text fields
                      _magiangvienController.text = '';
                      _hotenController.text = '';
                      _diachiController.text = '';
                      _sdtController.text = '';
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
  Future<void> _deleteProduct(String classId) async {
    await _giangVien.doc(classId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a class')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài Kiểm Tra Số 02'),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: _giangVien.snapshots(),
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
                        Text(documentSnapshot['maGiangVien']),
                        SizedBox(
                          height: 5,
                        ),
                        Text(documentSnapshot['hoTen']),
                        SizedBox(
                          height: 5,
                        ),
                        Text(documentSnapshot['diaChi']),
                      ],
                    )),
                    subtitle: Column(
                      children: [
                        Text(documentSnapshot['sdt'].toString()),
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