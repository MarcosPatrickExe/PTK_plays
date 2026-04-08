import 'package:flutter/material.dart';


void mostrarErroCustom( BuildContext context ) {
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // CARD PRINCIPAL
            Container(
              margin: EdgeInsets.only(top: 50),
              padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ops!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Não foi possível abrir o vídeo :/',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fechar'),
                  ),
                ],
              ),
            ),

            // IMAGEM CIRCULAR (SOBREPOSTA)
            Positioned(
              top: 0,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.red,
                child: Icon(
                  Icons.error,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          
        ),
      );
    },
  );
  
}