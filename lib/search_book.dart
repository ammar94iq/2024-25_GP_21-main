import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rawae_gp24/custom_navigation_bar.dart';

import 'book.dart';

class SearchBooksPage extends StatefulWidget {
  const SearchBooksPage({super.key});

  @override
  State<SearchBooksPage> createState() => _SearchBooksPageState();
}

class _SearchBooksPageState extends State<SearchBooksPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  void _searchBooks() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Thread')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      _searchResults = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'docID': doc.id, // حفظ document ID
          'image': data['bookCoverUrl'] ??
              'https://via.placeholder.com/150', // صورة افتراضية
          'name': data['title'] ?? 'Unknown Title', // اسم افتراضي
          'author': data['author'] ?? 'Unknown Author', // مؤلف افتراضي
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2835),
      body: Column(
        children: [
          const SizedBox(height: 25.0),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for a book...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                    ),
                    onSubmitted: (value) => _searchBooks(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _searchBooks,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No results found',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 18),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _searchResults.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 19.0,
                        crossAxisSpacing: 22.0,
                        childAspectRatio: 0.7,
                      ),
                      itemBuilder: (context, index) {
                        final book = _searchResults[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  print(
                                      "Navigating to BookDetailsPage with ID: ${book['docID']}");
                                  return BookDetailsPage(
                                      threadID: book['docID']);
                                },
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Image.network(
                                book['image'],
                                height: 200,
                                width: 130,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                book['name'],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(selectedIndex: 1),
    );
  }
}
