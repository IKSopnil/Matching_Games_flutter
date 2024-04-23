import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colors Game',
      theme: ThemeData(
        primaryColor: Colors.black,
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      home: const MyGame(),
      debugShowCheckedModeBanner: false, // Remove the debug banner
    );
  }
}

class MyGame extends StatefulWidget {
  const MyGame({Key? key}) : super(key: key);

  @override
  _MyGameState createState() => _MyGameState();
}

class _MyGameState extends State<MyGame> with TickerProviderStateMixin {
  late List<List<Color>> grid;
  final int rows = 5;
  final int columns = 5;
  late AudioCache _audioCache;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool blastAnimationVisible =
      false; // Track whether blast animation should be visible or not
  int score = 0;
  int highScore = 0;
  int remainingTime = 130;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    initializeGrid();
    _audioCache = AudioCache();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Start the timer when the game starts
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime--;
        if (remainingTime <= 0) {
          timer.cancel(); // Stop the timer
          if (!_checkAllSameColor()) {
            _showGameOver(); // Display "GAME OVER" if all boxes are not matched
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  void initializeGrid() {
    grid = List.generate(
        rows, (i) => List.filled(columns, Color.fromARGB(255, 38, 37, 37)));
  }

  void _onCellTap(int row, int col) {
    setState(() {
      grid[row][col] = _getRandomColor();
      if (_checkAllSameColor()) {
        _startFirecrackerAnimation(); // Change function call here
      }
    });
    _playSound();
    score++;
    if (score > highScore) {
      highScore = score;
    }
  }

  bool _checkAllSameColor() {
    Color firstColor = grid[0][0];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (grid[i][j] != firstColor) {
          return false;
        }
      }
    }
    return true;
  }

  void _playSound() {
    _audioCache.play('pop.mp3');
  }

  void _restartGame() {
    setState(() {
      initializeGrid();
      blastAnimationVisible = false; // Reset blast animation visibility
      if (score < highScore) {
        highScore =
            score; // Update high score only if current score beats high score
      }
      score = 0;
      remainingTime = 130; // Reset the remaining time
    });
  }

  Color _getRandomColor() {
    List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
    ];
    Random random = Random();
    return colors[random.nextInt(colors.length)];
  }

  void _startFirecrackerAnimation() {
    _controller.reset();
    _controller.forward();
    _playFirecrackerSound(); // Play firecracker sound
    setState(() {
      blastAnimationVisible = true; // Show firecracker animation
    });
  }

  void _playFirecrackerSound() {
    _audioCache.play('firecracker.mp3');
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'GAME OVER',
            style: TextStyle(
              color: Colors.red, // Set color to red
              fontWeight: FontWeight.bold,
              fontSize: 30, // Increase font size
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: Text(
                'Restart',
                style: TextStyle(
                  color: Colors.green, // Set color to green
                  fontSize: 20, // Adjust font size
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Colors Game',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        centerTitle: true, // Center the title
        backgroundColor:
            Color.fromARGB(255, 7, 7, 7), // Set the AppBar background color
      ),
      backgroundColor: Color.fromARGB(255, 7, 7, 7),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Match the colors of all the boxes",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text.rich(
              TextSpan(
                text: "Time Left: ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: "$remainingTime seconds",
                    style: TextStyle(
                      color: Colors.red, // Set color to red
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GridView.builder(
                  itemCount: rows * columns,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                  ),
                  itemBuilder: (context, index) {
                    int row = index ~/ columns;
                    int col = index % columns;
                    return GestureDetector(
                      onTap: () => _onCellTap(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          color: grid[row][col],
                        ),
                      ),
                    );
                  },
                ),
                // Display the blast animation if all boxes match
                if (blastAnimationVisible) ...[
                  Positioned.fill(
                    child: Image.asset(
                      'assets/firecracker.gif', // Adjust the path as per your project structure
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: ScaleTransition(
                        scale: _animation,
                        child: Text(
                          "WIN",
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.green, // Set color to green
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Moves: $score ",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Maximum Moves: $highScore ",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _restartGame,
        child: Icon(Icons.refresh),
        backgroundColor: Colors.black,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
