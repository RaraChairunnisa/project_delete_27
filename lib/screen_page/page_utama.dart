// screens/siswa_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../model/model_siswa.dart';

class SiswaScreen extends StatefulWidget {
  @override
  _SiswaScreenState createState() => _SiswaScreenState();
}

class _SiswaScreenState extends State<SiswaScreen> {
  List<Datum> siswa = [];
  List<Datum> filteredSiswa = [];
  TextEditingController searchController = TextEditingController();
  final String baseUrl = "http://192.168.1.9/siswa"; // Ganti dengan URL backend

  @override
  void initState() {
    super.initState();
    fetchSiswa();
    searchController.addListener(_filterSiswa);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSiswa() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.9/siswa/getSiswa.php'));
      if (response.statusCode == 200) {
        final List<Datum> fetchedSiswa = modelSiswaFromJson(response.body).data;
        setState(() {
          siswa = fetchedSiswa;
          filteredSiswa = fetchedSiswa;
        });
      } else {
        _showErrorSnackBar('Failed to load siswa');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load siswa: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void deleteSiswaDialog(Datum siswaItem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Siswa'),
          content: Text('Are you sure you want to delete this siswa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final response = await http.delete(
                    Uri.parse('$baseUrl/deleteSiswa.php?id=${siswaItem.id}'),
                  );
                  if (response.statusCode == 200) {
                    var responseData = json.decode(response.body);
                    if (responseData['is_success']) {
                      fetchSiswa(); // Refresh siswa list after deleting
                      Navigator.pop(context);
                    } else {
                      _showErrorSnackBar(responseData['message']);
                    }
                  } else {
                    _showErrorSnackBar('Failed to delete siswa');
                  }
                } catch (e) {
                  _showErrorSnackBar('Failed to delete siswa: $e');
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _filterSiswa() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredSiswa = siswa.where((siswaItem) {
        return siswaItem.namaSiswa.toLowerCase().contains(query) ||
            siswaItem.namaSekolah.toLowerCase().contains(query) ||
            siswaItem.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'List Siswa',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredSiswa.length,
        itemBuilder: (context, index) {
          final siswaItem = filteredSiswa[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              leading: Icon(Icons.person, size: 40, color: Colors.blue),
              title: Text(siswaItem.namaSiswa),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    'Sekolah: ${siswaItem.namaSekolah}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Email: ${siswaItem.email}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteSiswaDialog(siswaItem),
              ),
            ),
          );
        },
      ),
    );
  }
}
