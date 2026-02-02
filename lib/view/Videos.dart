import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';
import '../data/models/VideoNotification.dart';
import '../components/VideoCard.dart';

class Videos extends StatefulWidget {
  final YoutubeViewModel viewmodelYT;
  final String apiKEY;

  Videos({ required this.viewmodelYT, required this.apiKEY });

  @override
  State<Videos> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<Videos> {
  late Future<List<VideoNotification>> _videosCards;

  @override
  void initState() {
    super.initState();
    _videosCards = widget.viewmodelYT.loadVideos();
  }

  @override
  Widget build( BuildContext context ) { 
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      // APPBAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF121212),
        title: Row(
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.purple, size: 32),
            const SizedBox(width: 8),
            Text(
              'Videos',
               style: GoogleFonts.goldman(  textStyle: TextStyle( fontWeight: FontWeight.bold, fontSize: 22.0, color: Colors.white, ) ),
            ),
          ],
        ),
        actions: [
          // FILTRAR VIDEOS:
        //  IconButton( icon: const Icon( Icons.search, color: Colors.purple), onPressed: () {},  ),
          
          // NOTIFICACOES:
        //  IconButton( onPressed: null, icon: Icon( Icons.notification_important )),
          
          IconButton( onPressed: null, icon: Icon( Icons.dark_mode_outlined )),
           
          IconButton( onPressed: null, icon: Icon( Icons.light_mode_rounded )),
          
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            radius: 16,
            child: const Icon(Icons.person, color: Colors.purple),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // BODY
      body: FutureBuilder(
        future: this._videosCards,
        builder: (BuildContext bc, AsyncSnapshot<List<VideoNotification>> snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while waiting for data

            return Center( child: CircularProgressIndicator(color: Color.fromARGB(255, 213, 25, 255)));
            
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
            
          } else if (snapshot.hasData) {
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final notification = snapshot.data![index];

                return VideoCard(
                  notification: notification,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar( content: Text('Clicked: ${notification.videoTitle }') )
                    );
                  },
                );
              },
            );
            
          } else {
            return Center(child: Text('No posts found'));
          }
        },
      ),

      // BOTTOM
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        currentIndex: 1, // Notifications tab selected
        items: const [
          BottomNavigationBarItem(icon: Icon( Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon( Icons.notifications), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon( Icons.forum_rounded), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon( Icons.person_2_rounded), label: 'Perfil'),
        ],
        onTap: ( int optionSeletecd ){
          
        },
      ),
    );
  }
}
