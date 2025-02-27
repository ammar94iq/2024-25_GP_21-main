import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rawae_gp24/custom_navigation_bar.dart';
import 'package:rawae_gp24/makethread.dart';

import 'book.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1B2835),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 112, 28, 28),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To read',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // ✅ جلب قائمة المفضلة (BookMark)
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('BookMark')
                    .where('userID', isEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('An error event while bringing data',
                            style: TextStyle(color: Colors.white)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No Refined Books',
                            style: TextStyle(color: Colors.white)));
                  }

                  var bookmarks = snapshot.data!.docs;

                  return GridView.builder(
                    itemCount: bookmarks.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 19.0,
                      crossAxisSpacing: 22.0,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      var bookmark =
                          bookmarks[index].data() as Map<String, dynamic>;
                      String bookId = bookmark['threadID']
                          .toString(); // ✅ استخراج معرف الكتاب

                      // ✅ جلب بيانات الكتاب من Firestore باستخدام `bookmarkID`
                      return FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('Thread')
                            .doc(bookId)
                            .get(),
                        builder: (context,
                            AsyncSnapshot<DocumentSnapshot> bookSnapshot) {
                          if (bookSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              width: 140.0,
                              height: 200.0,
                              color: Colors
                                  .grey[800], // ✅ شكل مؤقت أثناء تحميل الكتاب
                            );
                          }
                          if (!bookSnapshot.hasData ||
                              !bookSnapshot.data!.exists) {
                            return const Center(
                                child: Text('The Book is not found',
                                    style: TextStyle(color: Colors.white)));
                          }

                          var bookData =
                              bookSnapshot.data!.data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    print(
                                        "📢 Navigating to BookDetailsPage with Firestore document ID: $bookId");
                                    return BookDetailsPage(threadID: bookId);
                                  },
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 140.0,
                                  height: 200.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.0),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          bookData['bookCoverUrl'] ?? ''),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  bookData['title'] ?? 'Unavailable title',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MakeThreadPage()),
          );
        },
        backgroundColor: const Color(0xFFD35400),
        elevation: 6,
        child: const Icon(
          Icons.add,
          size: 36,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomNavigationBar(selectedIndex: 2),
    );
  }
}
