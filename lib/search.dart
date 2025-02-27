import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'homepage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2835),
      appBar: AppBar(
        backgroundColor: const Color(0x00701C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Color(0xFF9DB2CE)),
            border: InputBorder.none,
          ),
          onChanged: (text) {
            setState(() {
              query = text;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF9DB2CE)),
            iconSize: 31,
            onPressed: () {
              setState(() {
                query = _searchController.text;
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Divider(color: Color.fromARGB(222, 62, 72, 72)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Thread')
                  .where('title', isGreaterThanOrEqualTo: query)
                  .where('title', isLessThan: query + 'z')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No results found.'));
                } else {
                  final threads = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: threads.length,
                    itemBuilder: (context, index) {
                      final threadData =
                          threads[index].data() as Map<String, dynamic>;
                      final List<dynamic> genreRefs =
                          threadData['genreID'] ?? [];
                      final String? bookCoverUrl = threadData['bookCoverUrl'];
                      final String threadId = threads[index].id;

                      return FutureBuilder<String>(
                        future: _getGenreNames(genreRefs),
                        builder: (context, genreSnapshot) {
                          if (!genreSnapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final genreNames = genreSnapshot.data!;
                          return BookListItem(
                            title: threadData['title'] ?? 'Untitled',
                            genre: genreNames,
                            isPopular: index == 0,
                            bookCoverUrl: bookCoverUrl,
                            threadId: threadId,
                            userId:
                                FirebaseAuth.instance.currentUser?.uid ?? '',
                            getContributors: _getContributors,
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getGenreNames(List<dynamic> genreRefs) async {
    List<String> genreNames = [];
    for (var genreRef in genreRefs) {
      if (genreRef is DocumentReference) {
        final genreSnapshot = await genreRef.get();
        if (genreSnapshot.exists) {
          genreNames.add(genreSnapshot['genreName'] ?? 'Unknown Genre');
        }
      }
    }
    return genreNames.join(', ');
  }

  Future<List<String>> _getContributors(String threadId) async {
    final threadDoc = await FirebaseFirestore.instance
        .collection('Thread')
        .doc(threadId)
        .get();
    final List<dynamic> contributorRefs = threadDoc['contributors'] ?? [];

    List<String> profileImageUrls = [];
    for (var ref in contributorRefs) {
      if (ref is DocumentReference) {
        final userSnapshot = await ref.get();
        if (userSnapshot.exists) {
          final data = userSnapshot.data() as Map<String, dynamic>;
          final profileImageUrl = data['profileImageUrl'] ?? '';
          profileImageUrls.add(profileImageUrl);
        }
      }
    }
    return profileImageUrls;
  }
}
