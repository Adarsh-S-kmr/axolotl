import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

late UserProfile userProfile;

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Center(
      child: Text(
        'Error: ${details.exceptionAsString()}',
        style: const TextStyle(color: Colors.red),
      ),
    );
  };

  userProfile = UserProfile(name: 'User', email: 'user@example.com');

  runApp(const NeuroBloomApp());
}

// DATA MODEL 1: GameAttempt
class GameAttempt {
  final int gameId;
  final String gameName;
  final double score; // 0-5
  final double accuracy; // 0-100
  final int reactionTime; // ms
  final DateTime timestamp;
  final String difficulty; // Easy, Medium, Hard, Expert
  final int benchmarkReactionTime;

  GameAttempt({
    required this.gameId,
    required this.gameName,
    required this.score,
    required this.accuracy,
    required this.reactionTime,
    required this.timestamp,
    required this.difficulty,
    required this.benchmarkReactionTime,
  });

  // Calculate learning velocity (score improvement per hour)
  double calculateLearningVelocity(GameAttempt? previousAttempt) {
    if (previousAttempt == null) return 0.5; // Neutral for first attempt

    double scoreDifference = score - previousAttempt.score;
    Duration timeDifference = timestamp.difference(previousAttempt.timestamp);
    double daysPassed =
        timeDifference.inSeconds / 86400.0; // Use days not hours

    // Avoid division by zero for same-day attempts
    if (daysPassed < 0.01) {
      // Less than ~15 minutes
      return scoreDifference * 10; // Just show raw improvement
    }

    return scoreDifference / daysPassed; // Score change per day
  }
}

// DATA MODEL 2: DomainScore
class DomainScore {
  final String name;
  final String emoji;
  double avgAccuracy = 0.0;
  double avgScore = 0.0;
  List<int> relatedGames = [];

  DomainScore({
    required this.name,
    required this.emoji,
    required this.relatedGames,
  });
}

// DATA MODEL 3: UserProfile
class UserProfile {
  String name;
  String email;
  int totalCoins = 0;
  Map<int, List<GameAttempt>> gameAttempts = {}; // gameId -> List of attempts
  double totalScore = 0.0;
  int gamesCompleted = 0;

  UserProfile({required this.name, required this.email});

  // Calculate cumulative score
  double calculateCumulativeScore() {
    if (gameAttempts.isEmpty) return 0.0;
    double total = 0.0;
    int count = 0;
    gameAttempts.forEach((gameId, attempts) {
      if (attempts.isNotEmpty) {
        total += attempts.last.score;
        count++;
      }
    });
    // Return average score (0-5) NOT sum
    return count > 0 ? (total / count) : 0.0;
  }

  // Get user classification (Group 1-4)
  String getClassification() {
    double avgScore = calculateCumulativeScore(); // Now 0-5 range
    if (avgScore <= 2.0) return 'Group 1: Foundational Training Needed';
    if (avgScore <= 3.0) return 'Group 2: Below Average';
    if (avgScore <= 4.0) return 'Group 3: Moderate to Good';
    return 'Group 4: High Cognitive Efficiency';
  }

  // Get classification color
  Color getClassificationColor() {
    double avgScore = calculateCumulativeScore();
    if (avgScore <= 2.0) return Colors.red[400]!;
    if (avgScore <= 3.0) return Colors.orange[400]!;
    if (avgScore <= 4.0) return Colors.blue[400]!;
    return Colors.green[400]!;
  }
}

class NeuroBloomApp extends StatelessWidget {
  const NeuroBloomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AXOLOTL',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB4D9E8),
          brightness: Brightness.light,
        ),
        fontFamily: 'Lexend',
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== DATA MODELS ====================

class GameState {
  final double score;
  final double accuracy;
  final double averageReactionTime;
  final bool isComplete;
  final int totalTrials;
  final int correctTrials;

  GameState({
    required this.score,
    required this.accuracy,
    required this.averageReactionTime,
    required this.isComplete,
    required this.totalTrials,
    required this.correctTrials,
  });
}

class GameEngine {
  final GameLevel gameLevel;
  late StreamController<GameState> _stateController;
  int correctTrials = 0;
  int totalTrials = 0;
  List<int> reactionTimes = [];

  GameEngine({required this.gameLevel}) {
    _stateController = StreamController<GameState>.broadcast();
  }

  Stream<GameState> get gameStateStream => _stateController.stream;

  void startGame() {
    _updateState();
  }

  void recordTrial(bool isCorrect, int reactionTime) {
    totalTrials++;
    if (isCorrect) correctTrials++;
    reactionTimes.add(reactionTime);
    _updateState();
  }

  void completeGame({
    required double score,
    required double accuracy,
    required double reactionTime,
  }) {
    final avgRT = reactionTimes.isEmpty
        ? reactionTime
        : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    _stateController.add(
      GameState(
        score: score,
        accuracy: accuracy,
        averageReactionTime: avgRT,
        isComplete: true,
        totalTrials: totalTrials,
        correctTrials: correctTrials,
      ),
    );
  }

  void _updateState() {
    final accuracy = totalTrials == 0
        ? 0.0
        : (correctTrials / totalTrials) * 100;
    final avgRT = reactionTimes.isEmpty
        ? 0.0
        : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    _stateController.add(
      GameState(
        score: accuracy / 20,
        accuracy: accuracy,
        averageReactionTime: avgRT,
        isComplete: false,
        totalTrials: totalTrials,
        correctTrials: correctTrials,
      ),
    );
  }

  void dispose() {
    _stateController.close();
  }
}

// ==================== STUNNING SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _breathingController;
  late AnimationController _waveController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    _mainController.forward();
    _breathingController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 800));
    _waveController.repeat();

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SignUpScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _breathingController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with elegant breathing animation
                  AnimatedBuilder(
                    animation: _breathingAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _breathingAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // App name with elegant typography
                  const Text(
                    'AXOLOTL',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: const Text(
                      'Adaptive Cognitive Training',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Elegant wave loader
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ElegantWavePainter(
                          animationValue: _waveController.value,
                        ),
                        size: const Size(100, 4),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Elegant wave loader painter
class ElegantWavePainter extends CustomPainter {
  final double animationValue;

  ElegantWavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;

    // Create 5 dots that move in wave pattern
    for (int i = 0; i < 5; i++) {
      final progress = (animationValue + i * 0.2) % 1.0;
      final x = i * (size.width / 4);
      final opacity = (sin(progress * pi * 2) * 0.5 + 0.5).clamp(0.3, 1.0);

      canvas.drawCircle(
        Offset(x, size.height / 2),
        size.height / 2,
        paint..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(ElegantWavePainter oldDelegate) => true;
}

// ==================== SIGN UP SCREEN ====================
// ==================== STUNNING SIGN UP SCREEN ====================
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animController;
  late AnimationController _glowController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _animController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _animController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      userProfile.name = 'Google User';
      userProfile.email = 'user@gmail.com';
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Signed in successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            name: userProfile.name,
            email: userProfile.email,
          ),
        ),
      );
    }
  }

  void _handleEmailSignUp() {
    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty) {
      userProfile.name = _nameController.text;
      userProfile.email = _emailController.text;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            name: _nameController.text,
            email: _emailController.text,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please fill in all fields'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF667EEA)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Animated logo with glow
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(
                                    0.3 * _glowAnimation.value,
                                  ),
                                  blurRadius: 40 * _glowAnimation.value,
                                  spreadRadius: 10 * _glowAnimation.value,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // App title - FIXED
                      const Text(
                        'Welcome to AXOLOTL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Train your brain, unlock your potential',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Main card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            children: [
                              if (_isLoading)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF667EEA),
                                              Color(0xFF764BA2),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Signing you in...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                _buildGoogleButton(),

                              const SizedBox(height: 28),

                              // Enhanced divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.grey.shade300,
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.grey.shade300,
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // Text fields
                              _buildTextField(
                                controller: _nameController,
                                hint: 'Your Name',
                                icon: Icons.person_outline_rounded,
                              ),

                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _emailController,
                                hint: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 32),

                              _buildGetStartedButton(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Terms text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.blue,
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const FittedBox(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade50, Colors.white],
        ),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleEmailSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ==================== STUNNING ONBOARDING SCREEN ====================
class OnboardingScreen extends StatefulWidget {
  final String name;
  final String email;

  const OnboardingScreen({Key? key, required this.name, required this.email})
    : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<double> _answers = [0, 0, 0, 0, 0, 0];
  final List<Map<String, dynamic>> _questions = [
    {
      'text': 'Rate your ability to stay focused on a single task',
      'icon': Icons.center_focus_strong_outlined,
      'subtitle': '0 = Cannot focus at all  •  100 = Perfect focus',
    },
    {
      'text': 'Rate your working memory capacity',
      'icon': Icons.memory_outlined,
      'subtitle': '0 = Very poor memory  •  100 = Excellent memory',
    },
    {
      'text': 'Rate your reaction speed to visual stimuli',
      'icon': Icons.flash_on_outlined,
      'subtitle': '0 = Very slow reactions  •  100 = Lightning fast',
    },
    {
      'text': 'Rate your ability to ignore distractions',
      'icon': Icons.not_interested_outlined,
      'subtitle': '0 = Easily distracted  •  100 = Highly resistant',
    },
    {
      'text': 'Rate your mental flexibility when switching tasks',
      'icon': Icons.compare_arrows_outlined,
      'subtitle': '0 = Very rigid thinking  •  100 = Extremely flexible',
    },
    {
      'text': 'Rate your problem-solving ability under pressure',
      'icon': Icons.psychology_outlined,
      'subtitle': '0 = Cannot solve problems  •  100 = Expert solver',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EAF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assessment,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Profile Setup',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C5F7F),
                                ),
                              ),
                              Text(
                                'Help us personalize your experience',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF667C8E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF667EEA),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _questions.length,
                  itemBuilder: (context, idx) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF667EEA,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _questions[idx]['icon'] as IconData,
                                  color: const Color(0xFF667EEA),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _questions[idx]['text'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C5F7F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 8,
                              activeTrackColor: const Color(0xFF667EEA),
                              inactiveTrackColor: Colors.grey[200],
                              thumbColor: const Color(0xFF667EEA),
                              overlayColor: const Color(
                                0xFF667EEA,
                              ).withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                            ),
                            child: Slider(
                              value: _answers[idx],
                              onChanged: (value) {
                                setState(() {
                                  _answers[idx] = value;
                                });
                              },
                              min: 0,
                              max: 100,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Low',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_answers[idx].round()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                'High',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Start Training',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const GameWorldScreen(),
    const TrainingModeScreen(),
    ProgressReportScreen(userProfile: userProfile, latestAttempts: {}),
    const ProfileScreen(),
  ];

  // Define your icons and labels
  final List<IconData> icons = [
    Icons.psychology_outlined,
    Icons.fitness_center_outlined,
    Icons.bar_chart_outlined,
    Icons.person_outline,
  ];

  final List<IconData> selectedIcons = [
    Icons.psychology,
    Icons.fitness_center,
    Icons.bar_chart,
    Icons.person,
  ];

  final List<String> labels = ['Test', 'Training', 'Progress', 'Profile'];

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    bool isSelected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF42A5F5).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF2C5F7F)
                      : Colors.grey[600],
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.85),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, icons[0], selectedIcons[0], labels[0]),
                _buildNavItem(1, icons[1], selectedIcons[1], labels[1]),
                _buildNavItem(2, icons[2], selectedIcons[2], labels[2]),
                _buildNavItem(3, icons[3], selectedIcons[3], labels[3]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrainingModeScreen extends StatelessWidget {
  const TrainingModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Training Mode Screen')));
  }
}

//progresss

class ProgressReportScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Map<int, GameAttempt?> latestAttempts;

  const ProgressReportScreen({
    Key? key,
    required this.userProfile,
    required this.latestAttempts,
  }) : super(key: key);

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Stunning App Bar with Gradient
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFFB4D9E8),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6DD5ED), Color(0xFF2193B0)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Beautiful User Avatar with Glow Effect
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.4),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: const Color(0xFF2193B0),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userProfile.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          userProfile.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards with Gradient
                    Row(
                      children: [
                        Expanded(
                          child: _buildGradientStatCard(
                            'Total Coins',
                            '${userProfile.totalCoins}',
                            Icons.monetization_on,
                            [const Color(0xFFFFA726), const Color(0xFFFF6F00)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGradientStatCard(
                            'Games Played',
                            '${userProfile.gamesCompleted}',
                            Icons.sports_esports,
                            [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGradientStatCard(
                            'Total Score',
                            '${userProfile.calculateCumulativeScore().toStringAsFixed(1)}',
                            Icons.star,
                            [const Color(0xFF66BB6A), const Color(0xFF2E7D32)],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGradientStatCard(
                            'Level',
                            _getShortClassification(),
                            Icons.emoji_events,
                            [const Color(0xFFAB47BC), const Color(0xFF6A1B9A)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Settings Section
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C5F7F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildModernSettingItem(
                            Icons.notifications_active,
                            'Notifications',
                            'Manage your alerts',
                            const Color(0xFFFF6B6B),
                            () {},
                          ),
                          _buildDivider(),
                          _buildModernSettingItem(
                            Icons.language,
                            'Language',
                            'Select your language',
                            const Color(0xFF4ECDC4),
                            () {},
                          ),
                          _buildDivider(),
                          _buildModernSettingItem(
                            Icons.help_outline,
                            'Help & Support',
                            'Get assistance',
                            const Color(0xFF45B7D1),
                            () {},
                          ),
                          _buildDivider(),
                          _buildModernSettingItem(
                            Icons.info_outline,
                            'About',
                            'App information',
                            const Color(0xFF96CEB4),
                            () {},
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getShortClassification() {
    String full = userProfile.getClassification();
    if (full.contains('Group 1')) return 'Beginner';
    if (full.contains('Group 2')) return 'Improving';
    if (full.contains('Group 3')) return 'Good';
    return 'Excellent';
  }

  Widget _buildGradientStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSettingItem(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: title == 'Notifications' ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C5F7F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }
}

// ==================== GAME WORLD SCREEN ====================

class GameWorldScreen extends StatefulWidget {
  const GameWorldScreen({Key? key}) : super(key: key);

  @override
  State<GameWorldScreen> createState() => _GameWorldScreenState();
}

class _GameWorldScreenState extends State<GameWorldScreen> {
  final List<GameLevel> games = [
    GameLevel(1, 'Trail Making', 'Task switching & sequencing', Icons.timeline),
    GameLevel(
      2,
      'Wisconsin Card Sorting',
      'Cognitive flexibility',
      Icons.dashboard,
    ),
    GameLevel(
      3,
      'Tower of London',
      'Planning & problem-solving',
      Icons.account_balance,
    ),
    GameLevel(4, 'Corsi Block-Tapping', 'Spatial memory', Icons.grid_3x3),
    GameLevel(5, 'Digit Span', 'Verbal working memory', Icons.dialpad),
    GameLevel(
      6,
      'Continuous Performance',
      'Sustained attention',
      Icons.track_changes,
    ),
    GameLevel(
      7,
      'Selective Attention',
      'Focus under distraction',
      Icons.search,
    ),
    GameLevel(8, 'Symbol Digit', 'Information processing', Icons.psychology),
    GameLevel(9, 'Reaction Time', 'Reflexes & accuracy', Icons.flash_on),
    GameLevel(10, 'Raven\'s Matrices', 'Pattern recognition', Icons.pattern),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF89F7FE), Color(0xFF66A6FF)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gamepad,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Cognitive Games',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black38,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Complete the games in sequence to unlock your profile.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 28),

              // Game List
              ...games.asMap().entries.map((entry) {
                int idx = entry.key;
                GameLevel game = entry.value;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + idx * 100),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GameScreen(gameLevel: game),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(
                                    const Color(0xFF42A5F5),
                                    const Color(0xFF1E88E5),
                                    idx / games.length,
                                  )!,
                                  Color.lerp(
                                    const Color(0xFF1E88E5),
                                    const Color(0xFF0D47A1),
                                    idx / games.length,
                                  )!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              game.icon,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  game.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF3B4F7C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF1E3A8A),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

// Example GameLevel class if needed
class GameLevel {
  final int id;
  final String name;
  final String description;
  final IconData icon;

  GameLevel(this.id, this.name, this.description, this.icon);
}

class DomainScoreBar extends StatelessWidget {
  final DomainScore domain;

  const DomainScoreBar({Key? key, required this.domain}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${domain.emoji} ${domain.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C5F7F),
              ),
            ),
            Text(
              '${domain.avgScore.toStringAsFixed(1)}/5',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: domain.avgScore / 5.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForScore(domain.avgScore),
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accuracy: ${domain.avgAccuracy.toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getColorForScore(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.blue;
    if (score >= 2.0) return Colors.orange;
    return Colors.red;
  }
}
// ========== STEP 7: Game Progress Item Widget ==========

class GameProgressItem extends StatelessWidget {
  final GameAttempt attempt;
  final double learningVelocity;

  const GameProgressItem({
    Key? key,
    required this.attempt,
    required this.learningVelocity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Consider velocity > 0.1 as positive (0.1 points per day)
    bool isPositiveTrend = learningVelocity > 0.1;
    bool isNeutral = learningVelocity.abs() <= 0.1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.gameName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C5F7F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Score: ${attempt.score.toStringAsFixed(1)}/5',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Acc: ${attempt.accuracy.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${attempt.difficulty} | RT: ${attempt.reactionTime}ms',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNeutral
                    ? Icons.trending_flat
                    : (isPositiveTrend
                          ? Icons.trending_up
                          : Icons.trending_down),
                color: isNeutral
                    ? Colors.grey
                    : (isPositiveTrend ? Colors.green : Colors.red),
              ),
              Text(
                isNeutral
                    ? 'Stable'
                    : '${learningVelocity > 0 ? '+' : ''}${learningVelocity.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isNeutral
                      ? Colors.grey
                      : (isPositiveTrend ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FinalReportScreen extends StatefulWidget {
  final UserProfile userProfile;
  final List<DomainScore> domains;

  const FinalReportScreen({
    Key? key,
    required this.userProfile,
    required this.domains,
  }) : super(key: key);

  @override
  State<FinalReportScreen> createState() => _FinalReportScreenState();
}

class _FinalReportScreenState extends State<FinalReportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cumulativeScore = widget.userProfile.calculateCumulativeScore();
    String classification = widget.userProfile.getClassification();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Final Report'),
        backgroundColor: const Color(0xFFB4D9E8),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Animated Summary Card
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[300]!, Colors.purple[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Congratulations!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You completed all 10 cognitive training games!',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${cumulativeScore.toStringAsFixed(1)}/10',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C5F7F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            classification,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.userProfile
                                  .getClassificationColor(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cognitive Profile Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cognitive Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5F7F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.domains.map((domain) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${domain.emoji} ${domain.name}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(domain.avgScore / 5.0 * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: domain.avgScore / 5.0,
                              minHeight: 12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getGradientColor(domain.avgScore),
                              ),
                              backgroundColor: Colors.grey[200],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Top Strengths
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Top Strengths',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._getTopThreeStrengths().map((strength) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(strength)),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Recommendations
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Recommended Practice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._getRecommendations().map((rec) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Coin Reward Summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Coins Earned',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.userProfile.totalCoins}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.monetization_on,
                    size: 64,
                    color: Colors.amber[400],
                  ),
                ],
              ),
            ),

            // Summary Text
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _generateSummaryText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Export/Share Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PDF export feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[400],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _getGradientColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.blue;
    if (score >= 2.0) return Colors.orange;
    return Colors.red;
  }

  List<String> _getTopThreeStrengths() {
    List<DomainScore> sortedDomains = List.from(widget.domains);
    sortedDomains.sort((a, b) => b.avgScore.compareTo(a.avgScore));
    return sortedDomains
        .take(3)
        .map(
          (d) =>
              '${d.emoji} ${d.name}: ${(d.avgScore / 5.0 * 100).toStringAsFixed(0)}%',
        )
        .toList();
  }

  List<String> _getRecommendations() {
    List<DomainScore> sortedDomains = List.from(widget.domains);
    sortedDomains.sort((a, b) => a.avgScore.compareTo(b.avgScore));
    return sortedDomains
        .take(2)
        .map(
          (d) =>
              'Focus on improving ${d.name} (currently at ${(d.avgScore / 5.0 * 100).toStringAsFixed(0)}%)',
        )
        .toList();
  }

  String _generateSummaryText() {
    List<DomainScore> sortedDomains = List.from(widget.domains);
    sortedDomains.sort((a, b) => b.avgScore.compareTo(a.avgScore));

    String topDomain = sortedDomains.first.name;
    String bottomDomain = sortedDomains.last.name;

    return 'You demonstrated excellent performance in $topDomain, showing strong cognitive abilities in this area. '
        'To enhance your overall cognitive profile, continue practicing exercises that target $bottomDomain. '
        'Your consistent effort and engagement with the training program is commendable. Keep up the great work!';
  }
}

// progress graph
class ProgressGraphWidget extends StatelessWidget {
  final UserProfile userProfile;

  const ProgressGraphWidget({Key? key, required this.userProfile})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get all attempts sorted by date
    List<GameAttempt> allAttempts = [];
    userProfile.gameAttempts.forEach((gameId, attempts) {
      allAttempts.addAll(attempts);
    });
    allAttempts.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (allAttempts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No progress data yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Calculate rolling average scores (smoothed over 3 games)
    List<double> smoothedScores = [];
    for (int i = 0; i < allAttempts.length; i++) {
      int start = (i - 1).clamp(0, allAttempts.length);
      int end = (i + 2).clamp(0, allAttempts.length);
      List<double> window = allAttempts
          .sublist(start, end)
          .map((a) => a.score)
          .toList();
      smoothedScores.add(window.reduce((a, b) => a + b) / window.length);
    }

    double maxScore = 5.0;
    double minScore = 0.0;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: ProgressGraphPainter(
          attempts: allAttempts,
          smoothedScores: smoothedScores,
          maxScore: maxScore,
          minScore: minScore,
        ),
        child: Container(),
      ),
    );
  }
}

class ProgressGraphPainter extends CustomPainter {
  final List<GameAttempt> attempts;
  final List<double> smoothedScores;
  final double maxScore;
  final double minScore;

  ProgressGraphPainter({
    required this.attempts,
    required this.smoothedScores,
    required this.maxScore,
    required this.minScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (attempts.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue.withOpacity(0.3), Colors.blue.withOpacity(0.05)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      double y = size.height - (i / 5 * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Plot points
    for (int i = 0; i < smoothedScores.length; i++) {
      double x = (i / (smoothedScores.length - 1)) * size.width;
      double normalizedScore =
          (smoothedScores[i] - minScore) / (maxScore - minScore);
      double y = size.height - (normalizedScore * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < smoothedScores.length; i++) {
      double x = (i / (smoothedScores.length - 1)) * size.width;
      double normalizedScore =
          (smoothedScores[i] - minScore) / (maxScore - minScore);
      double y = size.height - (normalizedScore * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(ProgressGraphPainter oldDelegate) => true;
}

// ==================== GAME SCREEN ====================
class GameScreen extends StatefulWidget {
  final GameLevel gameLevel;

  const GameScreen({Key? key, required this.gameLevel}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine gameEngine;

  @override
  void initState() {
    super.initState();
    gameEngine = GameEngine(gameLevel: widget.gameLevel);
    gameEngine.startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade500,
                Colors.purple.shade500,
                Colors.pink.shade400,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Game name
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.gameLevel.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Info icon
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.info_rounded,
                                  color: Colors.blue.shade600,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.gameLevel.name,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              widget.gameLevel.description,
                              style: TextStyle(height: 1.5),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Got it!'),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<GameState>(
        stream: gameEngine.gameStateStream,
        initialData: GameState(
          score: 0,
          accuracy: 0,
          averageReactionTime: 0,
          isComplete: false,
          totalTrials: 0,
          correctTrials: 0,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            GameState state = snapshot.data!;

            if (state.isComplete) {
              return GameResultScreen(
                score: state.score,
                accuracy: state.accuracy,
                reactionTime: state.averageReactionTime,
                gameLevel: widget.gameLevel,
                userProfile: userProfile,
              );
            }

            return GameRenderer(
              gameEngine: gameEngine,
              gameLevel: widget.gameLevel,
              state: state,
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  @override
  void dispose() {
    gameEngine.dispose();
    super.dispose();
  }
}

// ========== STEP 5: REPLACE ProgressReportScreen ==========

class _ProgressReportScreenState extends State<ProgressReportScreen>
    with SingleTickerProviderStateMixin {
  late List<DomainScore> domains;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeDomains();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeDomains() {
    domains = [
      DomainScore(
        name: 'Executive Function',
        emoji: '🧠',
        relatedGames: [1, 2, 3],
      ),
      DomainScore(name: 'Working Memory', emoji: '💾', relatedGames: [4, 5]),
      DomainScore(name: 'Attention', emoji: '👁️', relatedGames: [6, 7]),
      DomainScore(name: 'Processing Speed', emoji: '⚡', relatedGames: [8, 9]),
      DomainScore(name: 'Abstract Reasoning', emoji: '🎯', relatedGames: [10]),
    ];

    for (var domain in domains) {
      double totalAccuracy = 0.0;
      double totalScore = 0.0;
      int count = 0;

      for (int gameId in domain.relatedGames) {
        if (widget.userProfile.gameAttempts.containsKey(gameId)) {
          var attempts = widget.userProfile.gameAttempts[gameId]!;
          if (attempts.isNotEmpty) {
            totalAccuracy += attempts.last.accuracy;
            totalScore += attempts.last.score;
            count++;
          }
        }
      }

      if (count > 0) {
        domain.avgAccuracy = totalAccuracy / count;
        domain.avgScore = totalScore / count;
      }
    }
  }

  void _simulateGameCompletion() {
    setState(() {
      for (int gameId = 1; gameId <= 10; gameId++) {
        if (!widget.userProfile.gameAttempts.containsKey(gameId)) {
          widget.userProfile.gameAttempts[gameId] = [
            GameAttempt(
              gameId: gameId,
              gameName: 'Game $gameId',
              score: 3.5 + (gameId * 0.1),
              accuracy: 70.0 + (gameId * 2),
              reactionTime: 800 - (gameId * 20),
              timestamp: DateTime.now().subtract(Duration(days: 10 - gameId)),
              difficulty: 'Medium',
              benchmarkReactionTime: 1000,
            ),
          ];
        }
      }
      widget.userProfile.gamesCompleted = 10;
      widget.userProfile.totalCoins += 50;
      _initializeDomains();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('All games marked as complete!'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showGameDetails(GameAttempt attempt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF8FAFB)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(100, 100, 20, 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6DD5FA),
                                const Color(0xFF2980B9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6DD5FA).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.games_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attempt.gameName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A3A52),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(attempt.timestamp),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Performance Metrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A3A52),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildMetricCard(
                      'Score',
                      '${attempt.score.toStringAsFixed(2)}/5.0',
                      Icons.star_rounded,
                      const Color(0xFFFFB74D),
                      const Color(0xFFFFF3E0),
                      '${(attempt.score / 5.0 * 100).toStringAsFixed(0)}%',
                    ),
                    const SizedBox(height: 14),
                    _buildMetricCard(
                      'Accuracy',
                      '${attempt.accuracy.toStringAsFixed(1)}%',
                      Icons.check_circle_rounded,
                      const Color(0xFF66BB6A),
                      const Color(0xFFE8F5E9),
                      _getAccuracyRating(attempt.accuracy),
                    ),
                    const SizedBox(height: 14),
                    _buildMetricCard(
                      'Reaction Time',
                      '${attempt.reactionTime}ms',
                      Icons.flash_on_rounded,
                      const Color(0xFFFF7043),
                      const Color(0xFFFBE9E7),
                      _getReactionTimeRating(attempt.reactionTime),
                    ),
                    const SizedBox(height: 14),
                    _buildMetricCard(
                      'Difficulty Level',
                      attempt.difficulty,
                      Icons.trending_up_rounded,
                      const Color(0xFFAB47BC),
                      const Color(0xFFF3E5F5),
                      'Challenge completed',
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFE3F2FD),
                            const Color(0xFFBBDEFB),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.auto_graph_rounded,
                                  color: Color(0xFF2196F3),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Performance Analysis',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _getPerformanceAnalysis(attempt),
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF1A3A52),
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6DD5FA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A3A52),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Completed today';
    } else if (difference.inDays == 1) {
      return 'Completed yesterday';
    } else if (difference.inDays < 7) {
      return 'Completed ${difference.inDays} days ago';
    } else {
      return 'Completed ${date.day}/${date.month}/${date.year}';
    }
  }

  String _getAccuracyRating(double accuracy) {
    if (accuracy >= 90) return 'Excellent';
    if (accuracy >= 75) return 'Good';
    if (accuracy >= 60) return 'Average';
    return 'Needs Practice';
  }

  String _getReactionTimeRating(int rt) {
    if (rt < 500) return 'Very Fast';
    if (rt < 700) return 'Fast';
    if (rt < 900) return 'Average';
    return 'Slow';
  }

  String _getPerformanceAnalysis(GameAttempt attempt) {
    if (attempt.score >= 4.0 && attempt.accuracy >= 85) {
      return 'Outstanding performance! You\'ve demonstrated excellent mastery of this cognitive skill. Your quick reaction time and high accuracy show strong neural pathways.';
    } else if (attempt.score >= 3.0) {
      return 'Good job! You\'re performing well in this area. With continued practice, you can further improve your speed and accuracy.';
    } else if (attempt.score >= 2.0) {
      return 'You\'re making progress! This skill area shows potential for improvement. Regular practice will help strengthen these cognitive abilities.';
    } else {
      return 'Keep practicing! This is a challenging area, but consistent training will lead to significant improvements over time.';
    }
  }

  @override
  Widget build(BuildContext context) {
    double cumulativeScore = widget.userProfile.calculateCumulativeScore();
    String classification = widget.userProfile.getClassification();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'Progress Report',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A3A52),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFFD54F), const Color(0xFFFFA726)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB74D).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${widget.userProfile.totalCoins}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildOverallPerformanceCard(cumulativeScore, classification),
                  const SizedBox(height: 20),
                  _buildDomainPerformanceCard(),
                  const SizedBox(height: 20),
                  _buildProgressOverTimeCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                  _buildGameProgressCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallPerformanceCard(
    double cumulativeScore,
    String classification,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF8FAFB)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A3A52),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: cumulativeScore / 10.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.userProfile.getClassificationColor(),
                      ),
                      backgroundColor: Colors.grey[200],
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: cumulativeScore),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '${value.toStringAsFixed(1)}/10',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A3A52),
                          letterSpacing: -1,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(cumulativeScore / 10 * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.userProfile.getClassificationColor().withOpacity(0.15),
                  widget.userProfile.getClassificationColor().withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.userProfile.getClassificationColor().withOpacity(
                  0.3,
                ),
                width: 1.5,
              ),
            ),
            child: Text(
              classification,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: widget.userProfile.getClassificationColor(),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Games Completed: ${widget.userProfile.gamesCompleted}/10',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Domain Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A3A52),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          ...domains.asMap().entries.map((entry) {
            int index = entry.key;
            DomainScore domain = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < domains.length - 1 ? 16 : 0,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: DomainScoreBar(domain: domain),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProgressOverTimeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Over Time',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A3A52),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your average score across all games',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ProgressGraphWidget(userProfile: widget.userProfile),
        ],
      ),
    );
  }

  Widget _buildGameProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A3A52),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.userProfile.gameAttempts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.sports_esports_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No games completed yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete games to see your progress here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            ...widget.userProfile.gameAttempts.entries.map((entry) {
              List<GameAttempt> attempts = entry.value;
              if (attempts.isEmpty) return const SizedBox.shrink();

              GameAttempt latest = attempts.last;
              GameAttempt? previous = attempts.length > 1
                  ? attempts[attempts.length - 2]
                  : null;
              double learningVelocity = latest.calculateLearningVelocity(
                previous,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _showGameDetails(latest),
                  child: GameProgressItem(
                    attempt: latest,
                    learningVelocity: learningVelocity,
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.userProfile.gamesCompleted < 10)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _simulateGameCompletion,
              icon: const Icon(Icons.science_rounded, size: 20),
              label: const Text('Test Mode: Complete All Games'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6DD5FA), const Color(0xFF2980B9)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6DD5FA).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                if (domains.isEmpty) {
                  _initializeDomains();
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FinalReportScreen(
                      userProfile: widget.userProfile,
                      domains: domains,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.assessment_rounded, size: 22),
              label: Text(
                widget.userProfile.gamesCompleted >= 10
                    ? 'View Final Report'
                    : 'Preview Final Report',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== GAME RENDERER ====================
class GameRenderer extends StatelessWidget {
  final GameEngine gameEngine;
  final GameLevel gameLevel;
  final GameState state;

  const GameRenderer({
    Key? key,
    required this.gameEngine,
    required this.gameLevel,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (gameLevel.id) {
      case 1:
        return TrailMakingGame(gameEngine: gameEngine);
        ;
      case 2:
        return WisconsinCardSortingGame(gameEngine: gameEngine);
      case 3:
        return TowerOfLondonGame(gameEngine: gameEngine);
      case 4:
        return CorsiBlockGame(gameEngine: gameEngine);
      case 5:
        return DigitSpanGame(gameEngine: gameEngine);
      case 6:
        return ContinuousPerformanceGame(gameEngine: gameEngine);
      case 7:
        return SelectiveAttentionGame(gameEngine: gameEngine);
      case 8:
        return SymbolDigitGame(gameEngine: gameEngine);
      case 9:
        return ReactionTimeGame(gameEngine: gameEngine);
      case 10:
        return RavensMatricesGame(gameEngine: gameEngine);
      default:
        return const Center(child: Text('Game not found'));
    }
  }
}

// ==================== GAME RESULT SCREEN ====================
class GameResultScreen extends StatefulWidget {
  final double score;
  final double accuracy;
  final double reactionTime;
  final GameLevel gameLevel;
  final UserProfile userProfile;

  const GameResultScreen({
    Key? key,
    required this.score,
    required this.accuracy,
    required this.reactionTime,
    required this.gameLevel,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _statsController;
  late AnimationController _coinsController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  int coinsEarned = 0;
  bool isPersonalBest = false;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _coinsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _statsController, curve: Curves.easeIn));

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _saveGameAttempt();
    _startAnimations();
  }

  void _startAnimations() async {
    _celebrationController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _statsController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _coinsController.forward();
    _glowController.repeat(reverse: true);

    if (widget.score >= 4.0) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.mediumImpact();
      });
    } else {
      HapticFeedback.lightImpact();
    }
  }

  String _calculateDifficulty(double accuracy) {
    if (accuracy >= 90) return 'Expert';
    if (accuracy >= 75) return 'Hard';
    if (accuracy >= 60) return 'Medium';
    return 'Easy';
  }

  void _saveGameAttempt() {
    String difficulty = _calculateDifficulty(widget.accuracy);

    GameAttempt attempt = GameAttempt(
      gameId: widget.gameLevel.id,
      gameName: widget.gameLevel.name,
      score: widget.score,
      accuracy: widget.accuracy,
      reactionTime: widget.reactionTime.toInt(),
      timestamp: DateTime.now(),
      difficulty: difficulty,
      benchmarkReactionTime: 1000,
    );

    isPersonalBest = false;
    if (widget.userProfile.gameAttempts.containsKey(widget.gameLevel.id)) {
      var previousAttempts =
          widget.userProfile.gameAttempts[widget.gameLevel.id]!;
      if (previousAttempts.isNotEmpty) {
        double previousBest = previousAttempts
            .map((a) => a.score)
            .reduce((a, b) => a > b ? a : b);
        isPersonalBest = widget.score > previousBest;
      } else {
        isPersonalBest = true;
      }
    } else {
      isPersonalBest = true;
    }

    widget.userProfile.gameAttempts
        .putIfAbsent(widget.gameLevel.id, () => [])
        .add(attempt);

    coinsEarned = 5;
    if (isPersonalBest) coinsEarned += 10;
    if (widget.accuracy >= 90) coinsEarned += 5;

    widget.userProfile.totalCoins += coinsEarned;

    if (widget.userProfile.gameAttempts[widget.gameLevel.id]!.length == 1) {
      widget.userProfile.gamesCompleted++;
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _statsController.dispose();
    _coinsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.score >= 4.0
                ? [
                    Colors.purple.shade400,
                    Colors.blue.shade500,
                    Colors.cyan.shade400,
                  ]
                : [
                    Colors.blue.shade300,
                    Colors.lightBlue.shade400,
                    Colors.cyan.shade300,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Trophy with glow animation
                  AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (widget.score >= 4.0
                                                  ? Colors.amber
                                                  : Colors.blue)
                                              .withOpacity(
                                                _glowAnimation.value * 0.6,
                                              ),
                                      blurRadius: 30 * _glowAnimation.value,
                                      spreadRadius: 5 * _glowAnimation.value,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.score >= 4.5
                                      ? Icons.emoji_events
                                      : widget.score >= 3.5
                                      ? Icons.star
                                      : Icons.check_circle,
                                  size: 70,
                                  color: widget.score >= 4.0
                                      ? Colors.amber.shade600
                                      : Colors.blue.shade500,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Title
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            widget.score >= 4.5
                                ? '🎉 Outstanding!'
                                : widget.score >= 3.5
                                ? '🌟 Excellent Work!'
                                : widget.score >= 2.5
                                ? '👏 Well Done!'
                                : '✅ Complete!',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isPersonalBest) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade400,
                                    Colors.orange.shade500,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.military_tech,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'PERSONAL BEST!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stats card
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              'Score',
                              '${widget.score.toStringAsFixed(2)}/5',
                              Icons.stars_rounded,
                              Colors.purple,
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                              'Accuracy',
                              '${widget.accuracy.toStringAsFixed(1)}%',
                              Icons.precision_manufacturing_rounded,
                              Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                              'Reaction Time',
                              '${widget.reactionTime.toStringAsFixed(0)}ms',
                              Icons.speed_rounded,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Coins earned
                  AnimatedBuilder(
                    animation: _coinsController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _coinsController.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade300,
                                Colors.amber.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Coins Earned',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '+$coinsEarned',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Play Again',
                            icon: Icons.refresh_rounded,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: 'Home',
                            icon: Icons.home_rounded,
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade600,
                              ],
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== GAME 1: TRAIL MAKING ====================

class TrailMakingGame extends StatefulWidget {
  final GameEngine gameEngine;
  const TrailMakingGame({Key? key, required this.gameEngine}) : super(key: key);

  @override
  State<TrailMakingGame> createState() => _TrailMakingGameState();
}

class _TrailMakingGameState extends State<TrailMakingGame>
    with SingleTickerProviderStateMixin {
  List<TrailNode> nodes = [];
  int currentNodeIndex = 0;
  int score = 0;
  int errors = 0;
  Stopwatch stopwatch = Stopwatch();
  List<int> reactionTimes = [];
  int lastTapTime = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    stopwatch.start();
    lastTapTime = stopwatch.elapsedMilliseconds;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _generateTrail(double maxWidth, double maxHeight) {
    final random = Random();
    int numNodes = 10; // Reduced from 12
    const double minDistance = 120.0; // Increased from 100
    List<TrailNode> tempNodes = [];

    // Account for padding and node size
    const double padding = 60.0; // Increased padding
    const double nodeRadius = 30.0;

    final double usableWidth = maxWidth - (padding * 2) - (nodeRadius * 2);
    final double usableHeight = maxHeight - (padding * 2) - (nodeRadius * 2);

    for (int i = 0; i < numNodes; i++) {
      bool validPosition = false;
      Offset position = Offset.zero;
      int attempts = 0;
      const maxAttempts = 500; // Increased attempts

      while (!validPosition && attempts < maxAttempts) {
        position = Offset(
          random.nextDouble() * usableWidth + padding + nodeRadius,
          random.nextDouble() * usableHeight + padding + nodeRadius,
        );

        validPosition = true;
        for (var existingNode in tempNodes) {
          double distance = (position - existingNode.position).distance;
          if (distance < minDistance) {
            validPosition = false;
            break;
          }
        }
        attempts++;
      }

      tempNodes.add(TrailNode(id: i + 1, position: position));
    }

    setState(() {
      nodes = tempNodes;
    });
  }

  void _onNodeTap(int index) {
    if (index == currentNodeIndex) {
      int currentTime = stopwatch.elapsedMilliseconds;
      int reactionTime = currentTime - lastTapTime;
      reactionTimes.add(reactionTime);
      lastTapTime = currentTime;

      setState(() {
        currentNodeIndex++;
        score += 10;

        if (currentNodeIndex >= nodes.length) {
          stopwatch.stop();

          // Calculate accurate metrics
          double avgReactionTime = reactionTimes.isNotEmpty
              ? reactionTimes.reduce((a, b) => a + b) / reactionTimes.length
              : 0;

          int totalAttempts = currentNodeIndex + errors;
          double accuracy = totalAttempts > 0
              ? (currentNodeIndex / totalAttempts * 100)
              : 100;

          // FIXED: Score calculation for 0-5 range
          double completionBonus = currentNodeIndex.toDouble() * 10; // Max 120
          double timeBonus = max(
            0,
            60 - (stopwatch.elapsedMilliseconds / 1000),
          ); // Max 60
          double errorPenalty = errors * 10.0;

          double rawScore = completionBonus + timeBonus - errorPenalty;
          double finalScore = max(0, rawScore);

          // Normalize to 0-5 scale (max ~180, divide by 36)
          double normalizedScore = (finalScore / 36).clamp(0.0, 5.0);

          widget.gameEngine.completeGame(
            score: normalizedScore, // Returns 0-5
            accuracy: accuracy,
            reactionTime: avgReactionTime,
          );
        }
      });
    } else {
      setState(() {
        errors++;
        HapticFeedback.heavyImpact();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade50,
            Colors.purple.shade50,
            Colors.pink.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Generate nodes once with actual container size
                        if (nodes.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _generateTrail(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                          });
                        }

                        return nodes.isEmpty
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Colors.indigo.shade300,
                                ),
                              )
                            : Stack(
                                children: [
                                  CustomPaint(
                                    painter: TrailPainter(
                                      nodes: nodes,
                                      currentIndex: currentNodeIndex,
                                    ),
                                    size: Size.infinite,
                                  ),
                                  ...nodes.asMap().entries.map((entry) {
                                    int idx = entry.key;
                                    TrailNode node = entry.value;
                                    bool isCompleted = idx < currentNodeIndex;
                                    bool isActive = idx == currentNodeIndex;

                                    return Positioned(
                                      left: node.position.dx - 30,
                                      top: node.position.dy - 30,
                                      child: _buildNode(
                                        node,
                                        isCompleted,
                                        isActive,
                                        idx,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Score', '$score', Icons.stars_rounded, Colors.amber),
          _buildStatCard(
            'Errors',
            '$errors',
            Icons.error_outline_rounded,
            Colors.red,
          ),
          _buildStatCard(
            'Time',
            '${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s',
            Icons.timer_outlined,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(TrailNode node, bool isCompleted, bool isActive, int idx) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double scale = isActive ? 1.0 + (_pulseController.value * 0.1) : 1.0;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () => _onNodeTap(idx),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCompleted
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : isActive
                      ? [Colors.blue.shade400, Colors.blue.shade700]
                      : [Colors.grey.shade300, Colors.grey.shade400],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.4)
                        : isActive
                        ? Colors.blue.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: isActive ? 15 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text(
                  '${node.id}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isCompleted || isActive
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TrailNode {
  final int id;
  final Offset position;
  TrailNode({required this.id, required this.position});
}

class TrailPainter extends CustomPainter {
  final List<TrailNode> nodes;
  final int currentIndex;

  TrailPainter({required this.nodes, required this.currentIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connecting lines between completed nodes
    for (int i = 0; i < currentIndex - 1; i++) {
      _drawConnectingLine(canvas, nodes[i], nodes[i + 1]);
    }
  }

  void _drawConnectingLine(Canvas canvas, TrailNode start, TrailNode end) {
    // Calculate circle radius
    const double circleRadius = 30.0;

    // Calculate direction vector
    Offset direction = end.position - start.position;
    double distance = direction.distance;
    Offset normalizedDirection = direction / distance;

    // Adjust start and end points to touch circle edges
    Offset adjustedStart =
        start.position + (normalizedDirection * circleRadius);
    Offset adjustedEnd = end.position - (normalizedDirection * circleRadius);

    // Draw shadow line
    final shadowPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      adjustedStart + const Offset(2, 2),
      adjustedEnd + const Offset(2, 2),
      shadowPaint,
    );

    // Draw gradient line
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.blue.shade400, Colors.purple.shade400],
      ).createShader(Rect.fromPoints(adjustedStart, adjustedEnd))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(adjustedStart, adjustedEnd, paint);

    // Draw small circles at connection points for extra polish
    final dotPaint = Paint()
      ..color = Colors.green.shade500
      ..style = PaintingStyle.fill;

    canvas.drawCircle(adjustedStart, 3, dotPaint);
  }

  @override
  bool shouldRepaint(TrailPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex;
  }
}

// ==================== GAME 1: WISCONSIN CARD SORTING ====================
class WisconsinCardSortingGame extends StatefulWidget {
  final GameEngine gameEngine;

  const WisconsinCardSortingGame({Key? key, required this.gameEngine})
    : super(key: key);

  @override
  State<WisconsinCardSortingGame> createState() =>
      _WisconsinCardSortingGameState();
}

class _WisconsinCardSortingGameState extends State<WisconsinCardSortingGame>
    with SingleTickerProviderStateMixin {
  final List<CardRule> rules = [
    CardRule.color,
    CardRule.shape,
    CardRule.number,
  ];
  int currentRuleIndex = 0;

  int consecutiveCorrect = 0;
  int correctMatches = 0;
  int totalAttempts = 0;
  int categoriesCompleted = 0;

  late List<GameCard> stimulusCards;
  late GameCard responseCard;

  Timer? gameTimer;
  int remainingSeconds = 60;
  bool gameStarted = false;
  bool showRules = true;

  Stopwatch trialTimer = Stopwatch();
  List<int> reactionTimes = [];

  String feedbackText = "";
  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initializeGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    stimulusCards = [
      GameCard(color: CardColor.red, shape: CardShape.triangle, number: 1),
      GameCard(color: CardColor.green, shape: CardShape.star, number: 2),
      GameCard(color: CardColor.yellow, shape: CardShape.square, number: 3),
      GameCard(color: CardColor.blue, shape: CardShape.circle, number: 4),
    ];
    _generateResponseCard();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      showRules = false;
    });
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds <= 0) {
          _endGame();
        }
      });
    });
    trialTimer.start();
  }

  void _endGame() {
    gameTimer?.cancel();
    trialTimer.stop();

    double avgReactionTime = reactionTimes.isNotEmpty
        ? reactionTimes.reduce((a, b) => a + b) / reactionTimes.length
        : 0;

    double accuracy = totalAttempts > 0
        ? (correctMatches / totalAttempts * 100)
        : 0;

    // Score calculation (0-5 scale)
    double accuracyScore = (accuracy / 100) * 3; // Max 3 points for accuracy
    double categoryScore =
        (categoriesCompleted / rules.length) * 2; // Max 2 points for categories
    double finalScore = (accuracyScore + categoryScore).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: avgReactionTime,
    );
  }

  void _generateResponseCard() {
    final random = Random();
    responseCard = GameCard(
      color: CardColor.values[random.nextInt(CardColor.values.length)],
      shape: CardShape.values[random.nextInt(CardShape.values.length)],
      number: random.nextInt(4) + 1,
    );
    trialTimer.reset();
    feedbackText = "";
  }

  void _onCardTap(int index) {
    if (!gameStarted) return;

    totalAttempts++;
    int reactionTime = trialTimer.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    final rule = rules[currentRuleIndex];
    bool isCorrect = _isCorrectMatch(responseCard, stimulusCards[index], rule);

    setState(() {
      if (isCorrect) {
        correctMatches++;
        consecutiveCorrect++;
        feedbackText = "✓ Correct!";
        _feedbackController.forward().then(
          (_) => _feedbackController.reverse(),
        );
      } else {
        feedbackText = "✗ Try Again";
        consecutiveCorrect = 0;
        HapticFeedback.mediumImpact();
      }

      // Rule change after 5 consecutive correct
      if (consecutiveCorrect == 5) {
        currentRuleIndex = (currentRuleIndex + 1) % rules.length;
        consecutiveCorrect = 0;
        categoriesCompleted++;
        feedbackText = "🎉 Rule Changed!";
      }

      _generateResponseCard();
    });
  }

  bool _isCorrectMatch(GameCard response, GameCard stimulus, CardRule rule) {
    switch (rule) {
      case CardRule.color:
        return response.color == stimulus.color;
      case CardRule.shape:
        return response.shape == stimulus.shape;
      case CardRule.number:
        return response.number == stimulus.number;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showRules) {
      return _buildRulesScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
            Colors.pink.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFeedback(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Match this card:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 60),
              child: PlayingCard(card: responseCard, isTarget: true),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Tap one of these:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: stimulusCards.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: PlayingCard(card: stimulusCards[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.indigo.shade400, Colors.purple.shade600],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.psychology_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'Wisconsin Card Sorting',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          '🎯',
                          'Goal',
                          'Match cards based on a hidden rule (color, shape, or number)',
                        ),
                        _buildRuleItem(
                          '🤔',
                          'How to Play',
                          'Guess the rule by trying different matches. Feedback tells you if you\'re correct',
                        ),
                        _buildRuleItem(
                          '🔄',
                          'Rule Changes',
                          'After 5 consecutive correct answers, the rule changes without warning!',
                        ),
                        _buildRuleItem(
                          '⏱️',
                          'Time Limit',
                          'You have 60 seconds to score as many points as possible',
                        ),
                        _buildRuleItem(
                          '🎖️',
                          'Scoring',
                          'Your score depends on accuracy and categories completed',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Game',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('✓ Correct', '$correctMatches', Colors.green),
          _buildStatCard('📝 Total', '$totalAttempts', Colors.blue),
          _buildStatCard(
            '⏱️ Time',
            '${remainingSeconds}s',
            remainingSeconds > 10 ? Colors.orange : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    if (feedbackText.isEmpty) return SizedBox.shrink();

    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_feedbackController.value * 0.2),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            margin: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color:
                  feedbackText.contains('Correct') ||
                      feedbackText.contains('Changed')
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    feedbackText.contains('Correct') ||
                        feedbackText.contains('Changed')
                    ? Colors.green.shade400
                    : Colors.red.shade400,
                width: 2,
              ),
            ),
            child: Text(
              feedbackText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    feedbackText.contains('Correct') ||
                        feedbackText.contains('Changed')
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ENUMS AND CARD CLASSES =====================================

enum CardRule { color, shape, number }

enum CardColor { red, blue, green, yellow }

enum CardShape { circle, square, triangle, star }

class GameCard {
  final CardColor color;
  final CardShape shape;
  final int number;
  GameCard({required this.color, required this.shape, required this.number});
}

// CARD VIEW WIDGET ==========================================

class PlayingCard extends StatelessWidget {
  final GameCard card;
  final bool isTarget;

  const PlayingCard({Key? key, required this.card, this.isTarget = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTarget
              ? [Colors.blue.shade50, Colors.purple.shade50]
              : [Colors.white, Colors.grey.shade50],
        ),
        border: Border.all(
          color: isTarget ? Colors.blue.shade400 : Colors.grey.shade300,
          width: isTarget ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isTarget
                ? Colors.blue.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: isTarget ? 12 : 8,
            offset: Offset(0, isTarget ? 6 : 4),
          ),
        ],
      ),
      child: Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(card.number, (index) => _buildShape()),
        ),
      ),
    );
  }

  Widget _buildShape() {
    final color = _getColor(card.color);
    switch (card.shape) {
      case CardShape.circle:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        );
      case CardShape.square:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        );
      case CardShape.triangle:
        return CustomPaint(size: Size(30, 30), painter: TrianglePainter(color));
      case CardShape.star:
        return Icon(Icons.star, size: 30, color: color);
    }
  }

  Color _getColor(CardColor color) {
    switch (color) {
      case CardColor.red:
        return Colors.red.shade500;
      case CardColor.blue:
        return Colors.blue.shade500;
      case CardColor.green:
        return Colors.green.shade500;
      case CardColor.yellow:
        return Colors.amber.shade600;
    }
  }
}

// TRIANGLE RENDERER =========================================

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    // Shadow
    canvas.drawShadow(path, color.withOpacity(0.4), 3.0, false);
  }

  @override
  bool shouldRepaint(TrianglePainter old) => false;
}

// ==================== GAME 2: TOWER OF LONDON ====================
// ==================== GAME: TOWER OF LONDON (COMPLETE FIXED) ====================
class TowerOfLondonGame extends StatefulWidget {
  final GameEngine gameEngine;
  const TowerOfLondonGame({Key? key, required this.gameEngine})
    : super(key: key);

  @override
  State<TowerOfLondonGame> createState() => _TowerOfLondonGameState();
}

class _TowerOfLondonGameState extends State<TowerOfLondonGame> {
  List<List<BallColor>> pegs = [[], [], []];
  List<List<BallColor>> targetConfiguration = [[], [], []];
  int moves = 0;
  int optimalMoves = 3;
  int currentLevel = 1;
  int levelsCompleted = 0;

  BallColor? selectedBall;
  int? selectedPeg;

  Timer? gameTimer;
  int remainingSeconds = 60;
  bool gameStarted = false;
  bool showRules = true;

  List<int> movesList = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      showRules = false;
      _setupLevel();
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds <= 0) {
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    gameTimer?.cancel();

    // Calculate score (0-5)
    double efficiencyScore = movesList.isNotEmpty
        ? movesList.map((m) => m / optimalMoves).reduce((a, b) => a + b) /
              movesList.length
        : 0;
    double levelScore = (levelsCompleted / 5) * 3; // Max 3 points for levels
    double finalScore = ((1 - efficiencyScore) * 2 + levelScore).clamp(
      0.0,
      5.0,
    );

    // Fix accuracy calculation - should be 0-100
    double accuracy = (levelsCompleted / 5 * 100).clamp(0.0, 100.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy, // Now correctly 0-100
      reactionTime: 1000,
    );
  }

  void _setupLevel() {
    // Progressive difficulty
    if (currentLevel == 1) {
      pegs = [
        [BallColor.red, BallColor.blue],
        [BallColor.green],
        [],
      ];
      targetConfiguration = [
        [],
        [BallColor.red],
        [BallColor.blue, BallColor.green],
      ];
      optimalMoves = 3;
    } else if (currentLevel == 2) {
      pegs = [
        [BallColor.red, BallColor.green, BallColor.blue],
        [],
        [],
      ];
      targetConfiguration = [
        [],
        [],
        [BallColor.red, BallColor.green, BallColor.blue],
      ];
      optimalMoves = 4;
    } else if (currentLevel == 3) {
      pegs = [
        [BallColor.blue],
        [BallColor.green],
        [BallColor.red],
      ];
      targetConfiguration = [
        [BallColor.red, BallColor.green, BallColor.blue],
        [],
        [],
      ];
      optimalMoves = 5;
    } else if (currentLevel == 4) {
      pegs = [
        [],
        [BallColor.blue, BallColor.green],
        [BallColor.red],
      ];
      targetConfiguration = [
        [BallColor.red, BallColor.blue],
        [],
        [BallColor.green],
      ];
      optimalMoves = 4;
    } else {
      // Random configuration for level 5+
      _generateRandomLevel();
    }

    moves = 0;
    selectedBall = null;
    selectedPeg = null;
  }

  void _generateRandomLevel() {
    final random = Random();
    pegs = [[], [], []];
    targetConfiguration = [[], [], []];

    List<BallColor> allBalls = [BallColor.red, BallColor.green, BallColor.blue];
    allBalls.shuffle();

    // Random initial placement
    for (var ball in allBalls) {
      int peg = random.nextInt(3);
      while (pegs[peg].length >= 3) {
        peg = random.nextInt(3);
      }
      pegs[peg].add(ball);
    }

    // Random target (ensure it's different from initial)
    do {
      targetConfiguration = [[], [], []];
      allBalls.shuffle();
      for (var ball in allBalls) {
        int peg = random.nextInt(3);
        while (targetConfiguration[peg].length >= 3) {
          peg = random.nextInt(3);
        }
        targetConfiguration[peg].add(ball);
      }
    } while (_checkWin());

    optimalMoves = 4 + (currentLevel - 4);
  }

  void _onPegTap(int pegIndex) {
    if (!gameStarted) return;

    setState(() {
      if (selectedBall != null && selectedPeg != null) {
        // Move ball to this peg (all pegs hold max 3 balls)
        if (pegs[pegIndex].length < 3) {
          pegs[selectedPeg!].removeLast();
          pegs[pegIndex].add(selectedBall!);
          moves++;
          selectedBall = null;
          selectedPeg = null;

          if (_checkWin()) {
            movesList.add(moves);
            levelsCompleted++;
            currentLevel++;

            if (remainingSeconds > 0) {
              _showLevelComplete();
            }
          }
        } else {
          // Invalid move - peg full
          HapticFeedback.heavyImpact();
          selectedBall = null;
          selectedPeg = null;
        }
      } else if (pegs[pegIndex].isNotEmpty) {
        selectedBall = pegs[pegIndex].last;
        selectedPeg = pegIndex;
        HapticFeedback.lightImpact();
      }
    });
  }

  void _showLevelComplete() {
    // Just setup next level without popup
    setState(() {
      _setupLevel();
    });
  }

  bool _checkWin() {
    for (int i = 0; i < 3; i++) {
      if (pegs[i].length != targetConfiguration[i].length) return false;
      for (int j = 0; j < pegs[i].length; j++) {
        if (pegs[i][j] != targetConfiguration[i][j]) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (showRules) {
      return _buildRulesScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade50,
            Colors.blue.shade50,
            Colors.cyan.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Target Configuration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.teal.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: targetConfiguration.asMap().entries.map((
                          entry,
                        ) {
                          return Flexible(
                            child: TowerPeg(
                              balls: entry.value,
                              pegIndex: entry.key,
                              isTarget: true,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Your Configuration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 280,
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: pegs.asMap().entries.map((entry) {
                          int index = entry.key;
                          List<BallColor> pegBalls = entry.value;
                          return Flexible(
                            child: GestureDetector(
                              onTap: () => _onPegTap(index),
                              child: TowerPeg(
                                balls: pegBalls,
                                pegIndex: index,
                                isSelected: selectedPeg == index,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade400, Colors.cyan.shade600],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.account_tree_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'Tower of London',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          '🎯',
                          'Goal',
                          'Move colored balls to match the target configuration shown at the top',
                        ),
                        _buildRuleItem(
                          '🎮',
                          'How to Move',
                          'Tap a peg to select the top ball, then tap another peg to move it there',
                        ),
                        _buildRuleItem(
                          '📏',
                          'Rules',
                          'Each peg can hold up to 3 balls. You can only move the top ball from each peg',
                        ),
                        _buildRuleItem(
                          '🎖️',
                          'Optimal Moves',
                          'Try to complete each puzzle in the minimum number of moves shown',
                        ),
                        _buildRuleItem(
                          '⏱️',
                          'Time Limit',
                          'Solve as many puzzles as you can in 60 seconds!',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Game',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Level', '$currentLevel', Colors.purple),
          _buildStatCard('Moves', '$moves', Colors.blue),
          _buildStatCard('Optimal', '$optimalMoves', Colors.orange),
          _buildStatCard(
            'Time',
            '${remainingSeconds}s',
            remainingSeconds > 10 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum BallColor { red, blue, green, yellow }

class TowerPeg extends StatelessWidget {
  final List<BallColor> balls;
  final int pegIndex;
  final bool isTarget;
  final bool isSelected;

  const TowerPeg({
    Key? key,
    required this.balls,
    required this.pegIndex,
    this.isTarget = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.shade100
            : isTarget
            ? Colors.grey.shade50
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.blue.shade400
              : isTarget
              ? Colors.grey.shade400
              : Colors.grey.shade300,
          width: isSelected ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 8),
          // Label
          Text(
            'Peg ${pegIndex + 1}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          // Balls (max 3)
          ...balls.reversed.map(
            (ball) => Container(
              width: isTarget ? 32 : 36,
              height: isTarget ? 32 : 36,
              margin: EdgeInsets.only(bottom: isTarget ? 3 : 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getBallColor(ball),
                    _getBallColor(ball).withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: isTarget
                    ? []
                    : [
                        BoxShadow(
                          color: _getBallColor(ball).withOpacity(0.4),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          // Peg base
          Container(
            width: 50,
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.shade400, Colors.brown.shade600],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getBallColor(BallColor color) {
    switch (color) {
      case BallColor.red:
        return Colors.red.shade500;
      case BallColor.blue:
        return Colors.blue.shade500;
      case BallColor.green:
        return Colors.green.shade500;
      case BallColor.yellow:
        return Colors.amber.shade500;
    }
  }
}

// ==================== GAME 4: CORSI BLOCK-TAPPING ====================
// ==================== GAME: CORSI BLOCK TAPPING (COMPLETE FIXED) ====================
class CorsiBlockGame extends StatefulWidget {
  final GameEngine gameEngine;
  const CorsiBlockGame({Key? key, required this.gameEngine}) : super(key: key);

  @override
  State<CorsiBlockGame> createState() => _CorsiBlockGameState();
}

class _CorsiBlockGameState extends State<CorsiBlockGame>
    with SingleTickerProviderStateMixin {
  List<int> sequence = [];
  List<int> userSequence = [];
  int sequenceLength = 3;
  bool showingSequence = false;
  bool waitingForInput = false;
  int highlightedBlock = -1;
  int highestSpan = 3;
  int correctSequences = 0;
  int totalAttempts = 0;

  Timer? gameTimer;
  int remainingSeconds = 60;
  bool gameStarted = false;
  bool showRules = true;

  late AnimationController _pulseController;
  List<Offset> blockPositions = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _generateBlockPositions();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _generateBlockPositions() {
    // Reduced to 7 blocks for better mobile compatibility
    blockPositions = [
      Offset(60, 60),
      Offset(180, 70),
      Offset(290, 60),
      Offset(70, 180),
      Offset(280, 190),
      Offset(50, 310),
      Offset(190, 300),
    ];
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      showRules = false;
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds <= 0) {
          _endGame();
        }
      });
    });

    _startNewSequence();
  }

  void _endGame() {
    gameTimer?.cancel();

    // Score calculation (0-5 scale)
    // Span 3 = 0, Span 9 = 5 (linear scaling)
    double spanScore = ((highestSpan - 3) / 6.0 * 5.0).clamp(0.0, 5.0);

    double accuracy = totalAttempts > 0
        ? (correctSequences / totalAttempts * 100)
        : 0;

    widget.gameEngine.completeGame(
      score: spanScore,
      accuracy: accuracy,
      reactionTime: 1000,
    );
  }

  void _startNewSequence() {
    sequence = _generateSequence(sequenceLength);
    userSequence = [];
    _showSequence();
  }

  List<int> _generateSequence(int length) {
    final random = Random();
    List<int> seq = [];
    for (int i = 0; i < length; i++) {
      int newBlock;
      do {
        newBlock = random.nextInt(7); // Changed from 9 to 7
      } while (seq.isNotEmpty && newBlock == seq.last);
      seq.add(newBlock);
    }
    return seq;
  }

  void _showSequence() async {
    setState(() {
      showingSequence = true;
      waitingForInput = false;
    });

    await Future.delayed(Duration(milliseconds: 500));

    for (int i = 0; i < sequence.length; i++) {
      setState(() {
        highlightedBlock = sequence[i];
      });
      _pulseController.forward();
      await Future.delayed(Duration(milliseconds: 600));

      setState(() {
        highlightedBlock = -1;
      });
      _pulseController.reset();
      await Future.delayed(Duration(milliseconds: 300));
    }

    setState(() {
      showingSequence = false;
      waitingForInput = true;
    });
  }

  void _onBlockTap(int blockIndex) {
    if (!waitingForInput || !gameStarted) return;

    setState(() {
      userSequence.add(blockIndex);
      highlightedBlock = blockIndex;
    });

    _pulseController.forward().then((_) {
      Future.delayed(Duration(milliseconds: 200), () {
        setState(() {
          highlightedBlock = -1;
        });
        _pulseController.reset();
      });
    });

    // Check if correct
    if (userSequence.last != sequence[userSequence.length - 1]) {
      // Wrong block - end sequence
      HapticFeedback.heavyImpact();
      totalAttempts++;

      Future.delayed(Duration(milliseconds: 500), () {
        if (remainingSeconds > 0) {
          _startNewSequence();
        }
      });
    } else if (userSequence.length == sequence.length) {
      // Correct sequence completed
      HapticFeedback.lightImpact();
      correctSequences++;
      totalAttempts++;

      if (sequenceLength > highestSpan) {
        highestSpan = sequenceLength;
      }

      setState(() {
        sequenceLength++;
      });

      Future.delayed(Duration(milliseconds: 800), () {
        if (remainingSeconds > 0) {
          _startNewSequence();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showRules) {
      return _buildRulesScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade50,
            Colors.indigo.shade50,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: showingSequence
                      ? Colors.orange.shade100
                      : waitingForInput
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: showingSequence
                        ? Colors.orange.shade400
                        : waitingForInput
                        ? Colors.green.shade400
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showingSequence
                          ? Icons.visibility_rounded
                          : waitingForInput
                          ? Icons.touch_app_rounded
                          : Icons.hourglass_empty_rounded,
                      color: showingSequence
                          ? Colors.orange.shade700
                          : waitingForInput
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      showingSequence
                          ? 'Watch the sequence...'
                          : waitingForInput
                          ? 'Tap the blocks in order!'
                          : 'Get ready...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: showingSequence
                            ? Colors.orange.shade800
                            : waitingForInput
                            ? Colors.green.shade800
                            : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: List.generate(7, (index) {
                          bool isHighlighted = highlightedBlock == index;
                          return Positioned(
                            left: blockPositions[index].dx,
                            top: blockPositions[index].dy,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                double scale = isHighlighted
                                    ? 1.0 + (_pulseController.value * 0.15)
                                    : 1.0;

                                return Transform.scale(
                                  scale: scale,
                                  child: GestureDetector(
                                    onTap: () => _onBlockTap(index),
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isHighlighted
                                              ? [
                                                  Colors.blue.shade400,
                                                  Colors.blue.shade600,
                                                ]
                                              : [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade400,
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isHighlighted
                                                ? Colors.blue.withOpacity(0.5)
                                                : Colors.black.withOpacity(
                                                    0.15,
                                                  ),
                                            blurRadius: isHighlighted ? 15 : 8,
                                            offset: Offset(
                                              0,
                                              isHighlighted ? 6 : 4,
                                            ),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: isHighlighted
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepPurple.shade400, Colors.indigo.shade600],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.grid_4x4_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'Corsi Block Tapping',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          '🎯',
                          'Goal',
                          'Remember and reproduce sequences of blocks that light up on screen',
                        ),
                        _buildRuleItem(
                          '👀',
                          'Watch Phase',
                          'Watch carefully as blocks light up one by one in a specific sequence',
                        ),
                        _buildRuleItem(
                          '👆',
                          'Tap Phase',
                          'After the sequence ends, tap the blocks in the SAME ORDER they lit up',
                        ),
                        _buildRuleItem(
                          '📈',
                          'Progression',
                          'Each correct sequence makes the next one longer by 1 block',
                        ),
                        _buildRuleItem(
                          '⏱️',
                          'Time Limit',
                          'Complete as many sequences as possible in 60 seconds!',
                        ),
                        _buildRuleItem(
                          '🎖️',
                          'Scoring',
                          'Your score depends on the longest sequence (span) you achieve',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Game',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Span', '$sequenceLength', Colors.purple),
          _buildStatCard('Best', '$highestSpan', Colors.blue),
          _buildStatCard('Correct', '$correctSequences', Colors.green),
          _buildStatCard(
            'Time',
            '${remainingSeconds}s',
            remainingSeconds > 10 ? Colors.orange : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== GAME 5: DIGIT SPAN ====================
// ==================== GAME: DIGIT SPAN (COMPLETE FIXED) ====================
class DigitSpanGame extends StatefulWidget {
  final GameEngine gameEngine;
  const DigitSpanGame({Key? key, required this.gameEngine}) : super(key: key);

  @override
  State<DigitSpanGame> createState() => _DigitSpanGameState();
}

class _DigitSpanGameState extends State<DigitSpanGame>
    with SingleTickerProviderStateMixin {
  List<int> sequence = [];
  String userInput = '';
  int sequenceLength = 3;
  bool showingSequence = false;
  bool waitingForInput = false;
  int currentDigit = -1;
  int highestSpan = 3;
  int correctSequences = 0;
  int totalAttempts = 0;

  Timer? gameTimer;
  int remainingSeconds = 60;
  bool gameStarted = false;
  bool showRules = true;

  late AnimationController _digitController;

  @override
  void initState() {
    super.initState();
    _digitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _digitController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      showRules = false;
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds <= 0) {
          _endGame();
        }
      });
    });

    _startNewSequence();
  }

  void _endGame() {
    gameTimer?.cancel();

    // Score calculation (0-5 scale)
    // Span 3 = 0, Span 9 = 5 (linear scaling)
    double spanScore = ((highestSpan - 3) / 6.0 * 5.0).clamp(0.0, 5.0);

    double accuracy = totalAttempts > 0
        ? (correctSequences / totalAttempts * 100)
        : 0;

    widget.gameEngine.completeGame(
      score: spanScore,
      accuracy: accuracy,
      reactionTime: 1000,
    );
  }

  void _startNewSequence() {
    sequence = _generateDigitSequence(sequenceLength);
    userInput = '';
    currentDigit = -1;
    _showSequence();
  }

  List<int> _generateDigitSequence(int length) {
    final random = Random();
    List<int> seq = [];
    for (int i = 0; i < length; i++) {
      int newDigit;
      do {
        newDigit = random.nextInt(10);
      } while (seq.isNotEmpty && newDigit == seq.last);
      seq.add(newDigit);
    }
    return seq;
  }

  void _showSequence() async {
    setState(() {
      showingSequence = true;
      waitingForInput = false;
    });

    await Future.delayed(Duration(milliseconds: 500));

    for (int digit in sequence) {
      setState(() {
        currentDigit = digit;
      });
      _digitController.forward();
      await Future.delayed(Duration(milliseconds: 1000));
      _digitController.reverse();
      await Future.delayed(Duration(milliseconds: 400));
    }

    setState(() {
      showingSequence = false;
      waitingForInput = true;
      currentDigit = -1;
    });
  }

  void _onDigitTap(int digit) {
    if (!waitingForInput || !gameStarted) return;

    HapticFeedback.selectionClick();

    setState(() {
      userInput += digit.toString();
    });

    if (userInput.length == sequence.length) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    totalAttempts++;
    String correctSequence = sequence.join('');

    if (userInput == correctSequence) {
      // Correct!
      HapticFeedback.mediumImpact();
      correctSequences++;

      if (sequenceLength > highestSpan) {
        highestSpan = sequenceLength;
      }

      setState(() {
        sequenceLength++;
      });

      Future.delayed(Duration(milliseconds: 800), () {
        if (remainingSeconds > 0) {
          _startNewSequence();
        }
      });
    } else {
      // Wrong
      HapticFeedback.heavyImpact();

      Future.delayed(Duration(milliseconds: 800), () {
        if (remainingSeconds > 0) {
          _startNewSequence();
        }
      });
    }
  }

  void _onClearTap() {
    if (!waitingForInput) return;
    HapticFeedback.lightImpact();
    setState(() {
      userInput = '';
    });
  }

  void _onBackspaceTap() {
    if (!waitingForInput || userInput.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      userInput = userInput.substring(0, userInput.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showRules) {
      return _buildRulesScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade50,
            Colors.pink.shade50,
            Colors.red.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (showingSequence) _buildDigitDisplay(),
                  if (waitingForInput) _buildInputDisplay(),
                ],
              ),
            ),
            if (waitingForInput) _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitDisplay() {
    return AnimatedBuilder(
      animation: _digitController,
      builder: (context, child) {
        double scale = 1.0 + (_digitController.value * 0.2);

        return Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  currentDigit >= 0 ? '$currentDigit' : '',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputDisplay() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Enter the digits:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Text(
            userInput.isEmpty
                ? '_ ' * sequence.length
                : userInput.split('').join(' ') +
                      (' _' * (sequence.length - userInput.length)),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  int digit = index + 1;
                  return _buildNumberButton(digit);
                },
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Clear',
                    Icons.refresh_rounded,
                    Colors.orange,
                    _onClearTap,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(child: _buildNumberButton(0)),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Back',
                    Icons.backspace_rounded,
                    Colors.red,
                    _onBackspaceTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(int digit) {
    return GestureDetector(
      onTap: () => _onDigitTap(digit),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade300, Colors.blue.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$digit',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.shade300, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color.shade700, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange.shade400, Colors.red.shade500],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.numbers_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'Digit Span Test',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          '🎯',
                          'Goal',
                          'Remember sequences of digits and repeat them in the correct order',
                        ),
                        _buildRuleItem(
                          '👀',
                          'Watch Phase',
                          'Numbers will appear one at a time on screen. Pay close attention!',
                        ),
                        _buildRuleItem(
                          '🔢',
                          'Input Phase',
                          'After the sequence ends, use the number pad to enter the digits in the same order',
                        ),
                        _buildRuleItem(
                          '📈',
                          'Progression',
                          'Each correct sequence increases difficulty by adding one more digit',
                        ),
                        _buildRuleItem(
                          '⏱️',
                          'Time Limit',
                          'Complete as many sequences as possible in 60 seconds!',
                        ),
                        _buildRuleItem(
                          '🎖️',
                          'Scoring',
                          'Your score is based on the longest digit span you achieve',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Game',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Span', '$sequenceLength', Colors.orange),
          _buildStatCard('Best', '$highestSpan', Colors.red),
          _buildStatCard('Correct', '$correctSequences', Colors.green),
          _buildStatCard(
            'Time',
            '${remainingSeconds}s',
            remainingSeconds > 10 ? Colors.blue : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== GAME 6: CONTINUOUS PERFORMANCE TEST ====================
// ==================== GAME: CONTINUOUS PERFORMANCE TEST (COMPLETE FIXED) ====================
class ContinuousPerformanceGame extends StatefulWidget {
  final GameEngine gameEngine;
  const ContinuousPerformanceGame({Key? key, required this.gameEngine})
    : super(key: key);

  @override
  State<ContinuousPerformanceGame> createState() =>
      _ContinuousPerformanceGameState();
}

class _ContinuousPerformanceGameState extends State<ContinuousPerformanceGame>
    with SingleTickerProviderStateMixin {
  String currentLetter = '';
  String targetLetter = 'X';
  int trialCount = 0;
  int hits = 0;
  int falseAlarms = 0;
  int misses = 0;
  int correctRejections = 0;
  bool isShowingStimulus = false;
  bool hasResponded = false;

  Timer? gameTimer;
  int remainingSeconds = 60;
  bool gameStarted = false;
  bool showRules = true;

  Timer? stimulusTimer;
  Timer? intervalTimer;
  List<int> reactionTimes = [];
  Stopwatch reactionStopwatch = Stopwatch();

  late AnimationController _flashController;

  final List<String> letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'Y', 'Z', // Removed X from pool
  ];

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    stimulusTimer?.cancel();
    intervalTimer?.cancel();
    _flashController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      showRules = false;
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
        if (remainingSeconds <= 0) {
          _completeTest();
        }
      });
    });

    _showNextStimulus();
  }

  void _showNextStimulus() {
    if (!gameStarted || remainingSeconds <= 0) return;

    final random = Random();
    bool isTarget = random.nextDouble() < 0.25; // 25% target probability

    setState(() {
      currentLetter = isTarget
          ? targetLetter
          : letters[random.nextInt(letters.length)];
      isShowingStimulus = true;
      hasResponded = false;
      trialCount++;
    });

    reactionStopwatch.reset();
    reactionStopwatch.start();
    _flashController.forward();

    // Hide stimulus after 500ms
    stimulusTimer?.cancel();
    stimulusTimer = Timer(Duration(milliseconds: 500), () {
      if (!mounted) return;

      reactionStopwatch.stop();

      // Check for miss or correct rejection
      if (!hasResponded) {
        if (currentLetter == targetLetter) {
          setState(() => misses++);
        } else {
          setState(() => correctRejections++);
        }
      }

      setState(() {
        isShowingStimulus = false;
      });
      _flashController.reverse();
    });

    // Show next stimulus after 1200ms
    intervalTimer?.cancel();
    intervalTimer = Timer(Duration(milliseconds: 1200), () {
      if (mounted && gameStarted) {
        _showNextStimulus();
      }
    });
  }

  void _onScreenTap() {
    if (!isShowingStimulus || hasResponded || !gameStarted) return;

    hasResponded = true;
    reactionStopwatch.stop();
    int reactionTime = reactionStopwatch.elapsedMilliseconds;

    setState(() {
      if (currentLetter == targetLetter) {
        hits++;
        reactionTimes.add(reactionTime);
        HapticFeedback.mediumImpact();
      } else {
        falseAlarms++;
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _completeTest() {
    gameTimer?.cancel();
    stimulusTimer?.cancel();
    intervalTimer?.cancel();

    int totalTargets = hits + misses;
    int totalNonTargets = falseAlarms + correctRejections;

    double hitRate = totalTargets > 0 ? (hits / totalTargets * 100) : 0;
    double falseAlarmRate = totalNonTargets > 0
        ? (falseAlarms / totalNonTargets * 100)
        : 0;

    double avgReactionTime = reactionTimes.isEmpty
        ? 1000.0
        : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // Score calculation (0-5): Based on d' (sensitivity index)
    // Good performance: high hit rate, low false alarm rate
    double sensitivity = hitRate - falseAlarmRate;
    double normalizedScore = ((sensitivity + 100) / 200 * 5).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: normalizedScore,
      accuracy: hitRate,
      reactionTime: avgReactionTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showRules) {
      return _buildRulesScreen();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onScreenTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlue.shade50,
              Colors.cyan.shade50,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Target: $targetLetter',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _flashController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_flashController.value * 0.1),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isShowingStimulus
                                  ? (currentLetter == targetLetter
                                        ? [
                                            Colors.green.shade300,
                                            Colors.green.shade500,
                                          ]
                                        : [Colors.white, Colors.grey.shade100])
                                  : [Colors.white, Colors.grey.shade100],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isShowingStimulus
                                  ? (currentLetter == targetLetter
                                        ? Colors.green.shade600
                                        : Colors.grey.shade400)
                                  : Colors.grey.shade300,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isShowingStimulus
                                    ? (currentLetter == targetLetter
                                          ? Colors.green.withOpacity(0.4)
                                          : Colors.black.withOpacity(0.1))
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: isShowingStimulus ? 20 : 10,
                                offset: Offset(0, isShowingStimulus ? 8 : 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isShowingStimulus ? currentLetter : '',
                              style: TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.bold,
                                color: currentLetter == targetLetter
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.shade200, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: Colors.cyan.shade700,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tap anywhere when you see "$targetLetter"',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.cyan.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.cyan.shade400, Colors.teal.shade600],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.psychology_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'Continuous Performance Test',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          '🎯',
                          'Goal',
                          'Tap the screen ONLY when the target letter (X) appears',
                        ),
                        _buildRuleItem(
                          '👁️',
                          'Stay Focused',
                          'Letters will flash on screen rapidly. Watch carefully for the target!',
                        ),
                        _buildRuleItem(
                          '⚡',
                          'React Fast',
                          'Respond as quickly as possible when you see the target letter',
                        ),
                        _buildRuleItem(
                          '🚫',
                          'Avoid Mistakes',
                          'Don\'t tap when you see other letters - this counts as an error',
                        ),
                        _buildRuleItem(
                          '⏱️',
                          'Time Limit',
                          'The test runs for 60 seconds. Maintain focus throughout!',
                        ),
                        _buildRuleItem(
                          '🎖️',
                          'Scoring',
                          'Score is based on accuracy (hits vs false alarms) and reaction speed',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Trials', '$trialCount', Colors.blue),
          _buildStatCard('Hits', '$hits', Colors.green),
          _buildStatCard('Misses', '$misses', Colors.orange),
          _buildStatCard('False', '$falseAlarms', Colors.red),
          _buildStatCard(
            'Time',
            '${remainingSeconds}s',
            remainingSeconds > 10 ? Colors.teal : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== GAME 7: SELECTIVE ATTENTION TEST ====================
// ==================== GAME: SELECTIVE ATTENTION (COMPLETE FIXED) ====================

class SelectiveAttentionGame extends StatefulWidget {
  final GameEngine gameEngine;
  const SelectiveAttentionGame({Key? key, required this.gameEngine})
    : super(key: key);

  @override
  State<SelectiveAttentionGame> createState() => _SelectiveAttentionGameState();
}

class _SelectiveAttentionGameState extends State<SelectiveAttentionGame>
    with SingleTickerProviderStateMixin {
  List<SearchItem> items = [];
  SearchItem? targetItem;
  int correctResponses = 0;
  int incorrectResponses = 0;
  List<int> reactionTimes = [];
  Stopwatch trialStopwatch = Stopwatch();
  bool searchActive = false;

  Timer? gameTimer;
  int remainingSeconds = 60;
  bool gameStarted = false;
  bool showRules = true;

  late AnimationController _feedbackController;
  bool showCorrectFeedback = false;
  bool showWrongFeedback = false;

  bool _itemsGenerated = false;

  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  final List<IconData> shapes = [
    Icons.circle,
    Icons.square,
    Icons.change_history,
    Icons.star,
    Icons.hexagon,
  ];

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _feedbackController.dispose();
    trialStopwatch.stop();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      showRules = false;
      correctResponses = 0;
      incorrectResponses = 0;
      reactionTimes = [];
      remainingSeconds = 60;
    });

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          remainingSeconds--;
          if (remainingSeconds <= 0) {
            _completeTest();
          }
        });
      }
    });

    _startNewTrial();
  }

  void _startNewTrial() {
    if (!gameStarted || remainingSeconds <= 0) return;

    final random = Random();

    // Generate target
    targetItem = SearchItem(
      color: colors[random.nextInt(colors.length)],
      shape: shapes[random.nextInt(shapes.length)],
      position: const Offset(0, 0),
    );

    setState(() {
      searchActive = true;
      showCorrectFeedback = false;
      showWrongFeedback = false;
      _itemsGenerated = false; // Reset flag to regenerate items
      items = []; // Clear items
    });

    trialStopwatch.reset();
    trialStopwatch.start();
  }

  void _generateItems(double maxWidth, double maxHeight) {
    if (_itemsGenerated || targetItem == null) return;

    final random = Random();
    items = [];

    // Calculate grid based on available space
    int cols = (maxWidth / 100).floor().clamp(3, 5);
    int rows = (maxHeight / 100).floor().clamp(3, 5);
    int gridSize = cols * rows;

    // Ensure minimum grid size
    if (gridSize < 9) {
      cols = 3;
      rows = 3;
      gridSize = 9;
    }

    // Add target at random position
    int targetPosition = random.nextInt(gridSize);

    for (int i = 0; i < gridSize; i++) {
      double x = (i % cols) * (maxWidth / cols) + (maxWidth / cols / 2);
      double y = (i ~/ cols) * (maxHeight / rows) + (maxHeight / rows / 2);

      if (i == targetPosition) {
        items.add(
          SearchItem(
            color: targetItem!.color,
            shape: targetItem!.shape,
            position: Offset(x, y),
            isTarget: true,
          ),
        );
      } else {
        // Create distractor (conjunction search)
        Color distractorColor = colors[random.nextInt(colors.length)];
        IconData distractorShape = shapes[random.nextInt(shapes.length)];

        // Ensure distractor differs from target
        int attempts = 0;
        while ((distractorColor == targetItem!.color &&
                distractorShape == targetItem!.shape) &&
            attempts < 10) {
          distractorColor = colors[random.nextInt(colors.length)];
          distractorShape = shapes[random.nextInt(shapes.length)];
          attempts++;
        }

        items.add(
          SearchItem(
            color: distractorColor,
            shape: distractorShape,
            position: Offset(x, y),
            isTarget: false,
          ),
        );
      }
    }

    _itemsGenerated = true;
  }

  void _onItemTap(SearchItem item) {
    if (!searchActive || !gameStarted) return;

    trialStopwatch.stop();
    int reactionTime = trialStopwatch.elapsedMilliseconds;

    setState(() {
      searchActive = false;
      if (item.isTarget) {
        correctResponses++;
        reactionTimes.add(reactionTime);
        showCorrectFeedback = true;
        HapticFeedback.mediumImpact();
      } else {
        incorrectResponses++;
        showWrongFeedback = true;
        HapticFeedback.heavyImpact();
      }
    });

    _feedbackController.forward().then((_) {
      if (mounted) {
        _feedbackController.reverse();
      }
    });

    // Start next trial
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && gameStarted && remainingSeconds > 0) {
        _startNewTrial();
      }
    });
  }

  void _completeTest() {
    if (!mounted) return;

    gameTimer?.cancel();
    trialStopwatch.stop();

    setState(() {
      gameStarted = false;
      searchActive = false;
    });

    int totalTrials = correctResponses + incorrectResponses;
    double accuracy = totalTrials > 0
        ? (correctResponses / totalTrials * 100)
        : 0;
    double avgReactionTime = reactionTimes.isEmpty
        ? 2000.0
        : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // Score out of 5: Based on accuracy
    double normalizedScore = (accuracy / 100 * 5).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: normalizedScore,
      accuracy: accuracy,
      reactionTime: avgReactionTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showRules) {
      return _buildRulesScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade50,
            Colors.yellow.shade50,
            Colors.orange.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (showCorrectFeedback || showWrongFeedback) _buildFeedback(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (!_itemsGenerated && targetItem != null && searchActive) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _generateItems(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                        });
                      }
                    });
                  }

                  return Stack(
                    children: items.map((item) {
                      return Positioned(
                        left: item.position.dx - 35,
                        top: item.position.dy - 35,
                        child: AnimatedBuilder(
                          animation: _feedbackController,
                          builder: (context, child) {
                            double scale =
                                (showCorrectFeedback && item.isTarget)
                                ? 1.0 + (_feedbackController.value * 0.2)
                                : 1.0;

                            return Transform.scale(
                              scale: scale,
                              child: GestureDetector(
                                onTap: () => _onItemTap(item),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade100,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          (showCorrectFeedback && item.isTarget)
                                          ? Colors.green.shade600
                                          : (showWrongFeedback && !searchActive)
                                          ? Colors.red.shade400
                                          : Colors.grey.shade300,
                                      width:
                                          (showCorrectFeedback && item.isTarget)
                                          ? 3
                                          : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (showCorrectFeedback &&
                                                item.isTarget)
                                            ? Colors.green.withOpacity(0.4)
                                            : Colors.black.withOpacity(0.1),
                                        blurRadius:
                                            (showCorrectFeedback &&
                                                item.isTarget)
                                            ? 12
                                            : 6,
                                        offset: Offset(
                                          0,
                                          (showCorrectFeedback && item.isTarget)
                                              ? 6
                                              : 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    item.shape,
                                    color: item.color,
                                    size: 42,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_feedbackController.value * 0.1),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: showCorrectFeedback
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showCorrectFeedback
                    ? Colors.green.shade400
                    : Colors.red.shade400,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showCorrectFeedback ? Icons.check_circle : Icons.cancel,
                  color: showCorrectFeedback
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  showCorrectFeedback ? 'Correct!' : 'Wrong Item',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: showCorrectFeedback
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRulesScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.amber.shade400, Colors.orange.shade600],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.search_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selective Attention Test',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          '🎯',
                          'Goal',
                          'Find the target item (shown at top) as quickly as possible among distractors',
                        ),
                        _buildRuleItem(
                          '👀',
                          'Visual Search',
                          'Scan the screen for an item matching BOTH the color AND shape of the target',
                        ),
                        _buildRuleItem(
                          '⚡',
                          'Speed Matters',
                          'Tap the target as soon as you find it. Faster responses earn better scores!',
                        ),
                        _buildRuleItem(
                          '🚫',
                          'Avoid Mistakes',
                          'Be careful! Tapping wrong items counts as errors and reduces your score',
                        ),
                        _buildRuleItem(
                          '🔄',
                          'Continuous Trials',
                          'Each correct selection shows a new target. Keep searching!',
                        ),
                        _buildRuleItem(
                          '⏱️',
                          'Time Limit',
                          'Complete as many searches as possible in 60 seconds',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: The target shows at the top. Match BOTH color AND shape!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Correct', '$correctResponses', Colors.green),
              if (targetItem != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.purple.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Find This',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        targetItem!.shape,
                        color: targetItem!.color,
                        size: 36,
                      ),
                    ],
                  ),
                ),
              _buildStatCard('Wrong', '$incorrectResponses', Colors.red),
              _buildStatCard(
                'Time',
                '${remainingSeconds}s',
                remainingSeconds > 10 ? Colors.orange : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchItem {
  final Color color;
  final IconData shape;
  final Offset position;
  final bool isTarget;

  SearchItem({
    required this.color,
    required this.shape,
    required this.position,
    this.isTarget = false,
  });
}

// ==================== GAME 8: SYMBOL DIGIT TEST ====================
// ==================== GAME: SYMBOL DIGIT MODALITIES TEST (COMPLETE FIXED) ====================
class SymbolDigitGame extends StatefulWidget {
  final GameEngine gameEngine;
  const SymbolDigitGame({Key? key, required this.gameEngine}) : super(key: key);

  @override
  State<SymbolDigitGame> createState() => _SymbolDigitGameState();
}

class _SymbolDigitGameState extends State<SymbolDigitGame>
    with SingleTickerProviderStateMixin {
  Map<String, int> symbolDigitKey = {};
  String currentSymbol = '';
  int correctMatches = 0;
  int incorrectMatches = 0;
  List<int> reactionTimes = [];
  Stopwatch itemStopwatch = Stopwatch();

  Timer? gameTimer;
  int remainingTime = 90;
  bool gameStarted = false;
  bool showRules = true;

  late AnimationController _feedbackController;
  bool showCorrectFeedback = false;
  bool showWrongFeedback = false;

  final List<String> symbols = ['★', '◆', '●', '■', '▲', '♦', '♠', '♣', '♥'];

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _generateKey();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  void _generateKey() {
    final random = Random();
    List<int> digits = List.generate(9, (index) => index + 1);
    digits.shuffle(random);

    for (int i = 0; i < symbols.length; i++) {
      symbolDigitKey[symbols[i]] = digits[i];
    }
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      showRules = false;
    });

    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime--;
      });

      if (remainingTime <= 0) {
        _completeTest();
      }
    });

    _showNextSymbol();
  }

  void _showNextSymbol() {
    if (!gameStarted) return;

    final random = Random();
    setState(() {
      currentSymbol = symbols[random.nextInt(symbols.length)];
      showCorrectFeedback = false;
      showWrongFeedback = false;
    });

    itemStopwatch.reset();
    itemStopwatch.start();
  }

  void _onDigitTap(int digit) {
    if (!gameStarted) return;

    itemStopwatch.stop();
    int reactionTime = itemStopwatch.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    bool isCorrect = symbolDigitKey[currentSymbol] == digit;

    setState(() {
      if (isCorrect) {
        correctMatches++;
        showCorrectFeedback = true;
        HapticFeedback.mediumImpact();
      } else {
        incorrectMatches++;
        showWrongFeedback = true;
        HapticFeedback.heavyImpact();
      }
    });

    _feedbackController.forward().then((_) {
      _feedbackController.reverse();
    });

    // Show next symbol after brief delay
    Future.delayed(Duration(milliseconds: 400), () {
      if (mounted && gameStarted && remainingTime > 0) {
        _showNextSymbol();
      }
    });
  }

  void _completeTest() {
    gameTimer?.cancel();

    int totalAttempts = correctMatches + incorrectMatches;
    double accuracy = totalAttempts == 0
        ? 0
        : (correctMatches / totalAttempts) * 100;
    double avgReactionTime = reactionTimes.isEmpty
        ? 1000.0
        : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // Score out of 5: Based on correct matches in 90 seconds
    // Benchmark: 45 correct = 5 points, 0 correct = 0 points
    double normalizedScore = (correctMatches / 45.0 * 5.0).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: normalizedScore,
      accuracy: accuracy,
      reactionTime: avgReactionTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showRules) {
      return _buildRulesScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade50,
            Colors.purple.shade50,
            Colors.deepPurple.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSymbolKey(),
            _buildHeader(),
            if (showCorrectFeedback || showWrongFeedback) _buildFeedback(),
            const SizedBox(height: 12),
            _buildCurrentSymbol(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'What number matches this symbol?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDigitPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolKey() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade100, Colors.purple.shade100],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.indigo.shade300, width: 2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Symbol-Digit Key',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: symbols.length,
              padding: EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, index) {
                String symbol = symbols[index];
                return Container(
                  width: 45,
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade200, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(symbol, style: TextStyle(fontSize: 20)),
                      SizedBox(height: 1),
                      Text(
                        '${symbolDigitKey[symbol]}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSymbol() {
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        double scale = 1.0 + (_feedbackController.value * 0.1);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: showCorrectFeedback
                    ? Colors.green.shade600
                    : showWrongFeedback
                    ? Colors.red.shade600
                    : Colors.indigo.shade300,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: showCorrectFeedback
                      ? Colors.green.withOpacity(0.4)
                      : showWrongFeedback
                      ? Colors.red.withOpacity(0.4)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(currentSymbol, style: TextStyle(fontSize: 56)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDigitPad() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            int digit = index + 1;
            return GestureDetector(
              onTap: () => _onDigitTap(digit),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo.shade300, Colors.purple.shade500],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$digit',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_feedbackController.value * 0.1),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: showCorrectFeedback
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showCorrectFeedback
                    ? Colors.green.shade400
                    : Colors.red.shade400,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showCorrectFeedback ? Icons.check_circle : Icons.cancel,
                  color: showCorrectFeedback
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                SizedBox(width: 8),
                Text(
                  showCorrectFeedback ? 'Correct!' : 'Wrong',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: showCorrectFeedback
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRulesScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.indigo.shade500, Colors.purple.shade700],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.grid_3x3_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'Symbol Digit Modalities Test',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          '🔑',
                          'The Key',
                          'At the top, you\'ll see 9 symbols, each matched with a number (1-9)',
                        ),
                        _buildRuleItem(
                          '🎯',
                          'Your Task',
                          'A symbol appears in the center. Quickly tap the matching number based on the key',
                        ),
                        _buildRuleItem(
                          '⚡',
                          'Speed Counts',
                          'Work as fast and accurately as possible. Each correct match earns points!',
                        ),
                        _buildRuleItem(
                          '🧠',
                          'Memory Tip',
                          'Try to memorize the symbol-digit pairs to improve your speed over time',
                        ),
                        _buildRuleItem(
                          '⏱️',
                          'Time Limit',
                          'You have 90 seconds to complete as many matches as possible',
                        ),
                        _buildRuleItem(
                          '🎖️',
                          'Scoring',
                          'Score is based on total correct matches. Aim for 45+ for maximum points!',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Time',
            '${remainingTime}s',
            remainingTime > 30
                ? Colors.green
                : remainingTime > 10
                ? Colors.orange
                : Colors.red,
          ),
          _buildStatCard('Correct', '$correctMatches', Colors.green),
          _buildStatCard('Wrong', '$incorrectMatches', Colors.red),
          _buildStatCard(
            'Total',
            '${correctMatches + incorrectMatches}',
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== GAME 9: REACTION TIME TEST ====================
class ReactionTimeGame extends StatefulWidget {
  final GameEngine gameEngine;
  const ReactionTimeGame({Key? key, required this.gameEngine})
    : super(key: key);

  @override
  State<ReactionTimeGame> createState() => _ReactionTimeGameState();
}

class _ReactionTimeGameState extends State<ReactionTimeGame> {
  int currentTrial = 0;
  int maxTrials = 10;
  List<int> reactionTimes = [];
  bool waitingForStimulus = false;
  bool stimulusActive = false;
  bool showingResult = false;
  int lastReactionTime = 0;
  Color stimulusColor = Colors.red;
  Timer? stimulusTimer;
  Stopwatch reactionStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _startNextTrial();
  }

  void _startNextTrial() {
    if (currentTrial >= maxTrials) {
      _completeTest();
      return;
    }

    setState(() {
      waitingForStimulus = true;
      stimulusActive = false;
      showingResult = false;
      currentTrial++;
    });

    // Random delay between 1-4 seconds
    final random = Random();
    int delay = 1000 + random.nextInt(3000);

    stimulusTimer = Timer(Duration(milliseconds: delay), () {
      if (mounted) {
        setState(() {
          stimulusActive = true;
          waitingForStimulus = false;
          stimulusColor = Colors.green;
        });

        reactionStopwatch.reset();
        reactionStopwatch.start();
      }
    });
  }

  void _onScreenTap() {
    if (waitingForStimulus) {
      // Too early - penalty
      setState(() {
        waitingForStimulus = false;
        showingResult = true;
        lastReactionTime = -1; // Indicates too early
      });

      stimulusTimer?.cancel();

      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          _startNextTrial();
        }
      });
    } else if (stimulusActive) {
      // Correct response
      reactionStopwatch.stop();
      int reactionTime = reactionStopwatch.elapsedMilliseconds;
      reactionTimes.add(reactionTime);

      setState(() {
        stimulusActive = false;
        showingResult = true;
        lastReactionTime = reactionTime;
      });

      widget.gameEngine.recordTrial(true, reactionTime);

      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          _startNextTrial();
        }
      });
    }
  }

  void _completeTest() {
    if (reactionTimes.isEmpty) {
      widget.gameEngine.completeGame(
        score: 0.0,
        accuracy: 0.0,
        reactionTime: 1000.0,
      );
      return;
    }

    double avgReactionTime =
        reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;
    double variance =
        reactionTimes
            .map((rt) => pow(rt - avgReactionTime, 2).toDouble())
            .reduce((a, b) => a + b) /
        reactionTimes.length;
    double consistency = 1.0 - (variance / 10000.0).clamp(0.0, 1.0);

    // Score based on speed and consistency
    double speedScore = (500.0 / avgReactionTime).clamp(0.0, 1.0);
    double score = (speedScore + consistency) / 2.0 * 5.0;

    widget.gameEngine.completeGame(
      score: score,
      accuracy: (reactionTimes.length / maxTrials) * 100,
      reactionTime: avgReactionTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScreenTap,
      child: Scaffold(
        backgroundColor: waitingForStimulus
            ? Colors.red[100]
            : stimulusActive
            ? Colors.green
            : Colors.grey[100],
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Reaction Time Test',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Trial: $currentTrial/$maxTrials',
                      style: TextStyle(fontSize: 16),
                    ),
                    if (reactionTimes.isNotEmpty)
                      Text(
                        'Avg: ${(reactionTimes.reduce((a, b) => a + b) / reactionTimes.length).round()}ms',
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (waitingForStimulus) ...[
                        Icon(Icons.timer, size: 80, color: Colors.red),
                        SizedBox(height: 20),
                        Text(
                          'Wait for green...',
                          style: TextStyle(fontSize: 24),
                        ),
                        Text(
                          'Don\'t tap yet!',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ] else if (stimulusActive) ...[
                        Icon(Icons.flash_on, size: 80, color: Colors.green),
                        SizedBox(height: 20),
                        Text(
                          'TAP NOW!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ] else if (showingResult) ...[
                        Icon(
                          lastReactionTime == -1
                              ? Icons.close
                              : Icons.check_circle,
                          size: 80,
                          color: lastReactionTime == -1
                              ? Colors.red
                              : Colors.green,
                        ),
                        SizedBox(height: 20),
                        if (lastReactionTime == -1)
                          Text(
                            'Too Early!',
                            style: TextStyle(fontSize: 24, color: Colors.red),
                          )
                        else
                          Text(
                            '${lastReactionTime}ms',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ] else ...[
                        Icon(Icons.touch_app, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text('Get Ready...', style: TextStyle(fontSize: 24)),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tap the screen as quickly as possible when it turns green!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    stimulusTimer?.cancel();
    super.dispose();
  }
}

// ==================== GAME 10: RAVEN'S PROGRESSIVE MATRICES ====================
class RavensMatricesGame extends StatefulWidget {
  final GameEngine gameEngine;
  const RavensMatricesGame({Key? key, required this.gameEngine})
    : super(key: key);

  @override
  State<RavensMatricesGame> createState() => _RavensMatricesGameState();
}

class _RavensMatricesGameState extends State<RavensMatricesGame>
    with SingleTickerProviderStateMixin {
  int currentPuzzle = 0;
  int maxPuzzles = 12;
  int correctAnswers = 0;
  List<int> solutionTimes = [];
  Stopwatch puzzleStopwatch = Stopwatch();
  List<MatrixPuzzle> puzzles = [];

  bool gameStarted = false;
  bool showRules = true;

  late AnimationController _feedbackController;
  bool showCorrectFeedback = false;
  bool showWrongFeedback = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _generatePuzzles();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      showRules = false;
    });
    _startPuzzle();
  }

  void _generatePuzzles() {
    // Generate puzzles with logical patterns
    for (int i = 0; i < maxPuzzles; i++) {
      puzzles.add(_createPuzzleWithPattern(i));
    }
  }

  MatrixPuzzle _createPuzzleWithPattern(int difficulty) {
    final random = Random();
    List<List<MatrixCell>> matrix = [];

    // Choose pattern type based on difficulty
    int patternType = difficulty < 4
        ? 0
        : difficulty < 8
        ? 1
        : 2;

    // Pattern 0: Alternating shapes/colors
    // Pattern 1: Shape rotation or size progression
    // Pattern 2: Addition/subtraction of elements

    MatrixShape baseShape = MatrixShape.values[random.nextInt(4)];
    Color baseColor = [
      Colors.red,
      Colors.blue,
      Colors.green,
    ][random.nextInt(3)];

    // Generate 3x3 matrix with pattern
    for (int row = 0; row < 3; row++) {
      List<MatrixCell> matrixRow = [];
      for (int col = 0; col < 3; col++) {
        if (row == 2 && col == 2) {
          // Missing cell - to be solved
          matrixRow.add(
            MatrixCell(shape: MatrixShape.empty, color: Colors.white),
          );
        } else {
          // Apply pattern logic
          MatrixShape shape = _getShapeByPattern(
            row,
            col,
            baseShape,
            patternType,
          );
          Color color = _getColorByPattern(row, col, baseColor, patternType);
          matrixRow.add(MatrixCell(shape: shape, color: color));
        }
      }
      matrix.add(matrixRow);
    }

    // Determine correct answer based on pattern
    MatrixShape correctShape = _getShapeByPattern(2, 2, baseShape, patternType);
    Color correctColor = _getColorByPattern(2, 2, baseColor, patternType);
    MatrixCell correctAnswer = MatrixCell(
      shape: correctShape,
      color: correctColor,
    );

    // Generate options including correct answer
    List<MatrixCell> options = _generateOptionsWithCorrect(
      correctAnswer,
      random,
    );

    return MatrixPuzzle(
      id: difficulty,
      matrix: matrix,
      options: options,
      correctAnswer: options.indexOf(correctAnswer),
    );
  }

  MatrixShape _getShapeByPattern(
    int row,
    int col,
    MatrixShape base,
    int patternType,
  ) {
    if (patternType == 0) {
      // Alternating pattern
      return (row + col) % 2 == 0 ? base : _nextShape(base);
    } else if (patternType == 1) {
      // Column-based progression
      return MatrixShape.values[(base.index + col) % 4];
    } else {
      // Row-based progression
      return MatrixShape.values[(base.index + row) % 4];
    }
  }

  Color _getColorByPattern(int row, int col, Color base, int patternType) {
    List<Color> colors = [Colors.red, Colors.blue, Colors.green];
    int baseIndex = colors.indexOf(base);

    if (patternType == 0) {
      return colors[baseIndex];
    } else if (patternType == 1) {
      return colors[(baseIndex + row) % colors.length];
    } else {
      return colors[(baseIndex + col) % colors.length];
    }
  }

  MatrixShape _nextShape(MatrixShape current) {
    return MatrixShape.values[(current.index + 1) % 4];
  }

  List<MatrixCell> _generateOptionsWithCorrect(
    MatrixCell correct,
    Random random,
  ) {
    List<MatrixCell> options = [correct];

    // Generate 5 distractor options
    while (options.length < 6) {
      MatrixCell distractor = MatrixCell(
        shape: MatrixShape.values[random.nextInt(4)],
        color: [Colors.red, Colors.blue, Colors.green][random.nextInt(3)],
      );

      // Ensure no duplicates
      bool isDuplicate = options.any(
        (o) => o.shape == distractor.shape && o.color == distractor.color,
      );

      if (!isDuplicate) {
        options.add(distractor);
      }
    }

    options.shuffle(random);
    return options;
  }

  void _startPuzzle() {
    puzzleStopwatch.reset();
    puzzleStopwatch.start();
    setState(() {
      showCorrectFeedback = false;
      showWrongFeedback = false;
    });
  }

  void _onOptionTap(int optionIndex) {
    if (!gameStarted) return;

    puzzleStopwatch.stop();
    int solutionTime = puzzleStopwatch.elapsedMilliseconds;
    solutionTimes.add(solutionTime);

    bool isCorrect = optionIndex == puzzles[currentPuzzle].correctAnswer;

    setState(() {
      if (isCorrect) {
        correctAnswers++;
        showCorrectFeedback = true;
        HapticFeedback.mediumImpact();
      } else {
        showWrongFeedback = true;
        HapticFeedback.heavyImpact();
      }
    });

    _feedbackController.forward().then((_) {
      _feedbackController.reverse();
    });

    Future.delayed(Duration(milliseconds: 1000), () {
      if (!mounted) return;

      setState(() {
        currentPuzzle++;
      });

      if (currentPuzzle >= maxPuzzles) {
        _completeTest();
      } else {
        _startPuzzle();
      }
    });
  }

  void _completeTest() {
    double accuracy = (correctAnswers / maxPuzzles) * 100;
    double avgTime = solutionTimes.isEmpty
        ? 5000.0
        : solutionTimes.reduce((a, b) => a + b) / solutionTimes.length;

    // Score out of 5: Based on accuracy
    double normalizedScore = (accuracy / 100 * 5).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: normalizedScore,
      accuracy: accuracy,
      reactionTime: avgTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showRules) {
      return _buildRulesScreen();
    }

    if (currentPuzzle >= maxPuzzles) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple.shade400),
            SizedBox(height: 20),
            Text('Processing results...', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    MatrixPuzzle puzzle = puzzles[currentPuzzle];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade50,
            Colors.purple.shade50,
            Colors.pink.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (showCorrectFeedback || showWrongFeedback) _buildFeedback(),
            const SizedBox(height: 12), // Reduced spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Find the pattern and complete the matrix',
                style: TextStyle(
                  fontSize: 14, // Reduced font
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMatrix(puzzle.matrix),
            const SizedBox(height: 16), // Reduced spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Which option completes the pattern?',
                style: TextStyle(
                  fontSize: 13, // Reduced font
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              // Wrap options in Expanded to ensure visibility
              child: SingleChildScrollView(
                // Add scroll if needed
                child: _buildOptions(puzzle.options),
              ),
            ),
            const SizedBox(height: 10), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix(List<List<MatrixCell>> matrix) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16), // Reduced margin
      padding: EdgeInsets.all(8), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: matrix.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((cell) {
              return Container(
                width: 70, // Reduced from 90
                height: 70, // Reduced from 90
                margin: EdgeInsets.all(3), // Reduced margin
                decoration: BoxDecoration(
                  color: cell.shape == MatrixShape.empty
                      ? Colors.grey.shade200
                      : Colors.grey.shade50,
                  border: Border.all(
                    color: cell.shape == MatrixShape.empty
                        ? Colors.purple.shade300
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: cell.shape == MatrixShape.empty
                    ? Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: 36, // Reduced from 48
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade400,
                          ),
                        ),
                      )
                    : Center(
                        child: _buildShapeWidget(cell, 32),
                      ), // Reduced from 40
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptions(List<MatrixCell> options) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8), // Adjusted margins
      padding: EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true, // Important for proper sizing
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 10, // Reduced spacing
          mainAxisSpacing: 10, // Reduced spacing
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          MatrixCell option = options[index];
          return GestureDetector(
            onTap: () => _onOptionTap(index),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade50, Colors.grey.shade100],
                ),
                border: Border.all(color: Colors.purple.shade200, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.15),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: _buildShapeWidget(option, 28),
              ), // Reduced from 35
            ),
          );
        },
      ),
    );
  }

  Widget _buildShapeWidget(MatrixCell cell, double size) {
    switch (cell.shape) {
      case MatrixShape.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cell.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cell.color.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        );
      case MatrixShape.square:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cell.color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: cell.color.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        );
      case MatrixShape.triangle:
        return CustomPaint(
          size: Size(size, size),
          painter: TrianglePainter(cell.color),
        );
      case MatrixShape.diamond:
        return Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: cell.color,
              boxShadow: [
                BoxShadow(
                  color: cell.color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildFeedback() {
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_feedbackController.value * 0.1),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: showCorrectFeedback
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showCorrectFeedback
                    ? Colors.green.shade400
                    : Colors.red.shade400,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showCorrectFeedback ? Icons.check_circle : Icons.cancel,
                  color: showCorrectFeedback
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                SizedBox(width: 8),
                Text(
                  showCorrectFeedback ? 'Correct!' : 'Try Again Next Time',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: showCorrectFeedback
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRulesScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepPurple.shade400, Colors.purple.shade700],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.view_module_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'Raven\'s Progressive Matrices',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          '🧩',
                          'The Challenge',
                          'You\'ll see a 3×3 grid of shapes with one missing piece (bottom-right corner)',
                        ),
                        _buildRuleItem(
                          '🔍',
                          'Find the Pattern',
                          'Examine the relationships between shapes, colors, and positions to discover the underlying rule',
                        ),
                        _buildRuleItem(
                          '🎯',
                          'Complete It',
                          'Select the option from the 6 choices that logically completes the pattern',
                        ),
                        _buildRuleItem(
                          '📊',
                          'Common Patterns',
                          'Look for: alternating shapes, color progressions, rotation sequences, or position shifts',
                        ),
                        _buildRuleItem(
                          '🧠',
                          'Think Logically',
                          'Each puzzle follows a strict logical rule. Use abstract reasoning to solve it!',
                        ),
                        _buildRuleItem(
                          '📝',
                          'Scoring',
                          '12 puzzles total. Your score is based on accuracy and solving speed',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Start Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Puzzle',
            '${currentPuzzle + 1}/$maxPuzzles',
            Colors.purple,
          ),
          _buildStatCard('Correct', '$correctAnswers', Colors.green),
          _buildStatCard(
            'Wrong',
            '${currentPuzzle - correctAnswers}',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum MatrixShape { circle, square, triangle, diamond, empty }

class MatrixCell {
  final MatrixShape shape;
  final Color color;

  MatrixCell({required this.shape, required this.color});
}

class MatrixPuzzle {
  final int id;
  final List<List<MatrixCell>> matrix;
  final List<MatrixCell> options;
  final int correctAnswer;

  MatrixPuzzle({
    required this.id,
    required this.matrix,
    required this.options,
    required this.correctAnswer,
  });
}
