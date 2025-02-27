import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rawae_gp24/read_book.dart';

class BookDetailsPage extends StatefulWidget {
  final String threadID;

  const BookDetailsPage({super.key, required this.threadID});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  Map<String, dynamic>? bookData;
  List<String> authors = [];
  bool isBookmarked = false;
  String? bookmarkID; // سيتم استخدامه لحذف الإشارة المرجعية
  void checkIfBookmarked() async {
    String? userID = FirebaseAuth.instance.currentUser?.uid;

    QuerySnapshot bookmarkQuery = await FirebaseFirestore.instance
        .collection('BookMark')
        .where('userID', isEqualTo: userID)
        .where('threadID', isEqualTo: widget.threadID)
        .get();

    if (bookmarkQuery.docs.isNotEmpty) {
      setState(() {
        isBookmarked = true;
        bookmarkID = bookmarkQuery.docs.first.id; // حفظ ID المرجعية
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBookDetails();
    checkIfBookmarked(); // ✅ التحقق مما إذا كان الكتاب محفوظًا بالفعل
  }

  void toggleBookmark() async {
    String? userID = FirebaseAuth.instance.currentUser?.uid;
    CollectionReference bookmarks =
        FirebaseFirestore.instance.collection('BookMark');

    if (isBookmarked) {
      // 🗑️ **حذف الكتاب من المفضلة**
      await bookmarks.doc(bookmarkID).delete();
      setState(() {
        isBookmarked = false;
        bookmarkID = null;
      });
      print("❌ تم حذف الكتاب من المفضلة.");
    } else {
      // ✅ **إضافة الكتاب إلى المفضلة**
      DocumentReference bookmarkRef = await bookmarks.add({
        'userID': userID,
        'threadID': widget.threadID,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        isBookmarked = true;
        bookmarkID = bookmarkRef.id;
      });
      print("✅ تم حفظ الكتاب في المفضلة.");
    }
  }

  /// **Fetch only author names from Firestore**
  Future<List<String>> fetchAuthors(List<dynamic> authorRefs) async {
    List<String> authorNamesList = [];

    for (var authorRef in authorRefs) {
      if (authorRef is DocumentReference) {
        DocumentSnapshot authorDoc = await authorRef.get();

        if (authorDoc.exists) {
          authorNamesList
              .add(authorDoc['name'] ?? 'Unknown'); // ✅ Only get names
        }
      }
    }

    return authorNamesList;
  }

  /// **Fetch book details, including authors, from Firestore**
  void fetchBookDetails() async {
    print(
        "📢 Fetching book details for Firestore document ID: ${widget.threadID}");

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('Thread') // 🔍 Searching in 'Thread' collection
        .doc(widget.threadID) // ✅ Use Firestore document ID here
        .get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      print("✅ Book found: ${data['title']}");
      List<dynamic> authorRefs =
          data['contributors'] ?? []; // ✅ Get list of author references

      // Fetch author names only
      List<String> authorNames = await fetchAuthors(authorRefs);

      setState(() {
        bookData = data;
        authors = authorNames; // ✅ Store only names
      });
    } else {
      print("❌ Book not found in Firestore. Check the document ID.");
    }
  }

  /// **Build the Authors Section**
  Widget buildAuthorsSection() {
    if (authors.isEmpty) {
      return Text(
        "Authors: Unknown",
        style: TextStyle(color: Colors.grey[400], fontSize: 14),
      );
    }

    return Text(
      "Authors: ${authors.join(', ')}", // ✅ Display names as a comma-separated list
      style: TextStyle(color: Colors.grey[400], fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2835),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2835),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: toggleBookmark,
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            if (bookData != null) ...[
              Image.network(
                bookData!['bookCoverUrl'],
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported,
                      size: 100, color: Colors.grey);
                },
              ),
              const SizedBox(height: 20),
              Text(
                bookData!['title'],
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              buildAuthorsSection(), // ✅ Now shows authors dynamically
              const SizedBox(height: 20),
              Text(
                bookData!['description'] ?? "No description available.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ReadBookPage(threadID: widget.threadID)),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF344C64),
                        Color(0xFFD35400),
                        Color(0xFFA2DED0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Start Reading',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              const CircularProgressIndicator(), // ✅ Show loading until book data is fetched
          ],
        ),
      ),
    );
  }
}
