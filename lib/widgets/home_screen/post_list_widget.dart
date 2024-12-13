import 'dart:convert';
import 'dart:typed_data';
import 'package:autophile/core/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:autophile/widgets/home_screen/share_option.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timeago/timeago.dart' as timeago;


class PostListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> posts;



  PostListWidget({required this.posts});

  @override
  _PostListWidgetState createState() => _PostListWidgetState();
}

class _PostListWidgetState extends State<PostListWidget> {

  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<bool> checkIfFavorited(String postId) async {
    try {
      final userId = await storage.read(key: 'userId');
      final favoritesRef = await FirebaseFirestore.instance
          .collection('favourites')
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: postId)
          .get();

      return favoritesRef.docs.isNotEmpty;
    } catch (e) {
      print("Error checking if post is favorited: $e");
      return false;
    }
  }

  Future<bool> addToFavourite(String postId) async {
    try {
      final userId = await storage.read(key: 'userId');
      if (userId != null) {
        final favoritesRef = await FirebaseFirestore.instance
            .collection('favourites')
            .where('userId', isEqualTo: userId)
            .where('postId', isEqualTo: postId)
            .get();

        if (favoritesRef.docs.isNotEmpty) {
          await favoritesRef.docs.first.reference.delete();
          ToastUtils.showSuccess('Removed from favorites');
        } else {
          final favouriteDocRef = await FirebaseFirestore.instance
              .collection('favourites')
              .add({
            'postId': postId,
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          ToastUtils.showSuccess('Added to favorites');
          return true;
        }
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to add favorites')),
        );
        return false;
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
      return false;
    }
  }



  void _showCommentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: CommentWidget(
              username: 'User1',
              commentText: 'This is a comment',
              time: '5m ago',
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {


    return Column(
      children: widget.posts.map((post) {
        int likes = (post['likes'] is int)
            ? post['likes'] as int
            : 0;
        int dislikes = (post['dislikes'] is int)
            ? post['dislikes'] as int
            : 0;
        int comments = (post['comments'] is int)
            ? post['comments'] as int
            : 0;
        String caption = post['caption'] ?? '';
        List<String> tags = [];
        if (post['tags'] is List) {
          tags = List<String>.from(post['tags'] as List);
        } else if (post['tags'] is String) {
          tags = [post['tags'] as String];
        } else {
          tags = [];
        }
        Widget imageWidget;
        try {
          if (post['image'] != null && post['image'].toString().isNotEmpty) {
            Uint8List imageBytes = base64Decode(post['image'].toString());

            imageWidget = Image.memory(
              imageBytes,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return Image.asset(
                  'assets/placeholder.png',
                  width: double.infinity,
                  fit: BoxFit.contain,
                );
              },
            );
          } else {
            imageWidget = Image.asset(
              'assets/placeholder.png',
              width: double.infinity,
              fit: BoxFit.contain,
            );
          }
        } catch (e) {
          print('Error decoding base64 image: $e');
          imageWidget = Image.asset(
            'assets/placeholder.png',
            width: double.infinity,
            fit: BoxFit.contain,
          );
        }


        return Card(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Row
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(post['userId'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error loading user data');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            child: CircularProgressIndicator(),
                          ),
                          SizedBox(width: 10),
                          Text('Loading...'),
                        ],
                      );
                    }

                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                    final username = userData?['name'] ?? 'Unknown User';
                    final photoUrl = userData?['photo'] ?? '';

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: photoUrl == '' ?? true
                              ? NetworkImage('https://static.vecteezy.com/system/resources/previews/019/879/186/non_2x/user-icon-on-transparent-background-free-png.png')
                              : NetworkImage(photoUrl),

                          onBackgroundImageError: (_, __) {
                            print('Error loading image');
                          },
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timeago.format(DateTime.parse(post['createdAt'] ?? DateTime.now().toString())),
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        FutureBuilder<bool>(
                          future: checkIfFavorited(post['postId']),
                          builder: (context, initialSnapshot) {
                            bool isFavorited = initialSnapshot.data ?? false;

                            return StatefulBuilder(
                              builder: (context, setLocalState) {
                                return IconButton(
                                  icon: Icon(
                                    isFavorited ? Icons.bookmark : Icons.bookmark_border,
                                    color: isFavorited ? Colors.orange : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    setLocalState(() {
                                      isFavorited = !isFavorited;
                                    });

                                    try {
                                      await addToFavourite(post['postId']);
                                    } catch (e) {
                                      setLocalState(() {
                                        isFavorited = !isFavorited;
                                      });
                                      print('Error toggling favorite: $e');
                                    }
                                  },
                                );
                              },
                            );
                          },
                        )
                      ],
                    );
                  },
                ),
                SizedBox(height: 10),

                Text(caption, style: TextStyle(fontSize: 14)),
                SizedBox(height: 10),

                // Tags
                Wrap(
                  spacing: 8,
                  children: tags.map((tag) => Chip(
                    label: Text('#$tag'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
                SizedBox(height: 10),

                // Post Image
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageWidget,
                  ),
                ),
                SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Image.asset('assets/icons/upvote.png'),
                          onPressed: () {
                          },
                        ),
                        Text('$likes'),
                      ],
                    ),

                    Row(
                      children: [
                        IconButton(
                          icon: Image.asset('assets/icons/downvote.png'),
                          onPressed: () {
                          },
                        ),
                        Text('$dislikes'),
                      ],
                    ),

                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.chat_bubble_outline),
                          onPressed: () => _showCommentModal(context),
                        ),
                        Text('$comments'),
                      ],
                    ),


                    // Share Button and Count
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.share_outlined, size: 24),
                          color: Colors.grey,
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => ShareOptions(
                                postLink:  "https://autophile.com/path-to-user-image.jpg",
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                              ),
                            );
                          },

                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CommentWidget extends StatefulWidget {
  final String username;
  final String commentText;
  final String time;

  const CommentWidget({
    required this.username,
    required this.commentText,
    required this.time,
    Key? key,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),

              Text(
                'Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Info Icon
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                },
              ),
            ],
          ),
        ),

        Divider(height: 1, color: Colors.grey),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('assets/images/profile _picture.png'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.time,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.commentText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Icon(Icons.emoji_emotions_outlined, size: 28),
                Icon(Icons.sentiment_satisfied_alt, size: 28),
                Icon(Icons.sentiment_dissatisfied, size: 28),
                Icon(Icons.sentiment_very_dissatisfied, size: 28),
                Icon(Icons.sentiment_neutral, size: 28),
                Icon(Icons.sentiment_very_satisfied, size: 28),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/images/profile _picture.png'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                  },
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}