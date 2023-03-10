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
      title: 'Bài kiểm  tra 1 đề 3',
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
  final TextEditingController _malophocController = TextEditingController();
  final TextEditingController _tenlopController = TextEditingController();
  final TextEditingController _soluongsinhvienController = TextEditingController();
  final TextEditingController _magiangvienController = TextEditingController();

  final CollectionReference _lophoc =
  FirebaseFirestore.instance.collection('lophoc');

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _malophocController.text = documentSnapshot['masv'];
      _tenlopController.text = documentSnapshot['ngaysinh'];
      _soluongsinhvienController.text = documentSnapshot['masv'].toString();
      _magiangvienController.text = documentSnapshot['quequan'];
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
                  controller: _malophocController,
                  decoration: const InputDecoration(labelText: 'Malophoc'),
                ),
                TextField(
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  controller: _soluongsinhvienController,
                  decoration: const InputDecoration(
                    labelText: 'soluongsv',
                  ),
                ),
                TextField(
                  controller: _tenlopController,
                  decoration: const InputDecoration(labelText: 'Ten lop hoc'),
                ),
                TextField(
                  controller: _magiangvienController,
                  decoration: const InputDecoration(labelText: 'magiangvien'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? malophoc = _malophocController.text;
                    final String? tenlophoc = _tenlopController.text;
                    final String? magiangvien = _magiangvienController.text;
                    final double? soluongsv =
                    double.tryParse(_soluongsinhvienController.text);
                    if (malophoc != null && tenlophoc != null && magiangvien != null && soluongsv != null) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _lophoc.add({"malophoc": malophoc, "tenlophoc": tenlophoc, "soluongsv": soluongsv, "magiangvien": magiangvien});
                      }

                      if (action == 'update') {
                        // Update the product
                        await _lophoc
                            .doc(documentSnapshot!.id)
                            .update({"malophoc": malophoc, "tenlophoc": tenlophoc, "soluongsv": soluongsv, "magiangvien": magiangvien});
                      }

                      // Clear the text fields
                      _malophocController.text = '';
                      _soluongsinhvienController.text = '';
                      _tenlopController.text = '';
                      _magiangvienController.text = '';

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
  Future<void> _deleteProduct(String lophocId) async {
    await _lophoc.doc(lophocId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a class')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bai tap ve nha de so3'),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: _lophoc.snapshots(),
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
                          Text(documentSnapshot['malophoc']),
                          Text(documentSnapshot['tenlophoc']),
                          Text(documentSnapshot['soluongsv'].toString()),
                          Text(documentSnapshot['magiangvien']),
                        ],
                      ),),
                    // subtitle: Text(documentSnapshot['soluongsv'].toString()),
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