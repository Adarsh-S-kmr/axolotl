// File: game_implementations_phase2.dart
import 'package:flutter/material.dart';// Adjust this import path as necessary
import 'peakstuff.dart';
// ==================== PHASE 2 GAME STUBS (IDs 11-35) ====================
// NOTE: These stubs rely on GameEngine, which must be accessible via mport.

// 11-15: Executive Function
// File: game_implementations_ef.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

// ==================== GLOBAL RULES SCREEN HELPERS ====================

// 1. RuleItem Class Definition
class RuleItem {
  final String emoji;
  final String title;
  final String description;
  RuleItem(this.emoji, this.title, this.description);
}

// 2. _buildGenericRulesScreen Function Definition
Widget _buildGenericRulesScreen({
  required String title,
  required String description,
  required List<RuleItem> rules,
  required VoidCallback onStart,
  required IconData icon,
  required List<Color> gradientColors,
  required Color themeColor,
}) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(icon, size: 80, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem('🎯', 'Goal', description, themeColor),
                        ...rules.map((rule) => _buildRuleItem(rule.emoji, rule.title, rule.description, themeColor)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
                child: const Text('Start Game', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// NOTE: This helper function must also be defined/available
Widget _buildRuleItem(String emoji, String title, String description, Color themeColor) {
  return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
      const SizedBox(height: 4),
      Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
    ]),
    ),],),
  );
}
// NOTE: These core classes must be accessible via import from your main file (proj.txt)
// Assuming GameEngine, GameLevel, GameState, and GameResultScreen are available.

// --------------------------------------------------------------------------
// HELPER ENUMS AND DATA MODELS (Executive Function Games)
// --------------------------------------------------------------------------
// NOTE: Ensure your main file imports 'package:flutter/material.dart';

// --------------------------------------------------------------------------
// HELPER ENUMS AND DATA MODELS (Executive Function Games)
// --------------------------------------------------------------------------

// Logic Gates Challenge & Category Switch
enum StimulusColor { red, blue, green, yellow }
enum StimulusShape { circle, square, triangle, star }
enum CardProperty { color, shape, number, size }
enum LogicalRule { colorToShape, shapeToNumber, parityToSize, positionToColor } // For Logic Gates

class EFCard {
  final StimulusColor color;
  final StimulusShape shape;
  final int number; // 1, 2, 3
  final double size; // 1.0, 1.5, 2.0 (for parity)
  EFCard({required this.color, required this.shape, required this.number, required this.size});
}

class LogicGatesGame extends StatefulWidget {
  final GameEngine gameEngine;
  const LogicGatesGame({super.key, required this.gameEngine});
  @override
  State<LogicGatesGame> createState() => _LogicGatesGameState();
}

class _LogicGatesGameState extends State<LogicGatesGame> with SingleTickerProviderStateMixin {
  LogicalRule currentRule = LogicalRule.colorToShape;
  // NOTE: EFCard needs its const removed if it holds non-const values, but for simple values it's fine.
  EFCard currentCard = EFCard(color: StimulusColor.red, shape: StimulusShape.circle, number: 1, size: 1.0);
  String feedback = 'Infer the Rule!';
  int consecutiveCorrect = 0;
  int totalTrials = 0;
  int correctTrials = 0;
  List<int> reactionTimes = [];
  Stopwatch trialStopwatch = Stopwatch();
  Timer? gameTimer;
  int remainingSeconds = 60;
  bool gameStarted = false;
  late AnimationController _feedbackController;

  final List<LogicalRule> rules = LogicalRule.values;
  final List<String> ruleNames = ['Color Match', 'Shape Match', 'Number Match', 'Size Match'];

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _initializeGame();
  }
  @override void dispose() { gameTimer?.cancel(); _feedbackController.dispose(); super.dispose(); }

  void _initializeGame() {
    currentRule = rules[Random().nextInt(rules.length)];
    _generateCard();
  }
  void _startGame() {
    setState(() { gameTimer?.cancel(); gameStarted = true; remainingSeconds = 60; totalTrials = 0; correctTrials = 0; });
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() { remainingSeconds--; if (remainingSeconds <= 0) _endGame(); });
    });
    trialStopwatch.start();
  }
  void _generateCard() {
    final random = Random();
    currentCard = EFCard(
      color: StimulusColor.values[random.nextInt(StimulusColor.values.length)],
      shape: StimulusShape.values[random.nextInt(StimulusShape.values.length)],
      number: random.nextInt(3) + 1,
      size: random.nextBool() ? 1.0 : 2.0,
    );
    trialStopwatch.reset();
    trialStopwatch.start();
  }

  // CORE LOGIC FIX: Check if the tapped rule matches the actual hidden rule.
  void _onCategoryTap(LogicalRule tappedRule) {
    if (!gameStarted || feedback.contains('Rule Changed')) return;
    totalTrials++;
    int reactionTime = trialStopwatch.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    // Check 1: Did the user correctly guess the name of the active rule?
    bool isCorrectGuess = (tappedRule == currentRule);

    setState(() {
      if (isCorrectGuess) {
        correctTrials++;
        consecutiveCorrect++;
        feedback = '✓ Correct Rule Guess! ($consecutiveCorrect)';

        if (consecutiveCorrect >= 4) {
          LogicalRule newRule;
          do { newRule = rules[Random().nextInt(rules.length)]; } while (newRule == currentRule);
          currentRule = newRule;
          consecutiveCorrect = 0;
          feedback = '🎉 Rule Changed! (New Rule)';
        }
      } else {
        consecutiveCorrect = 0;
        feedback = '✗ Incorrect. Try Again.';
        HapticFeedback.mediumImpact();
      }
      _feedbackController.forward().then((_) => _feedbackController.reverse());
      _generateCard();
    });
    widget.gameEngine.recordTrial(isCorrectGuess, reactionTime);
  }

  void _endGame() {
    gameTimer?.cancel(); trialStopwatch.stop();
    double accuracy = totalTrials > 0 ? (correctTrials / totalTrials * 100) : 0;
    double avgRT = reactionTimes.isEmpty ? 1000.0 : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;
    double accuracyScore = (accuracy / 100) * 3;
    double shiftScore = (totalTrials / 30).clamp(0.0, 2.0);
    double finalScore = (accuracyScore + shiftScore).clamp(0.0, 5.0);
    widget.gameEngine.completeGame(score: finalScore, accuracy: accuracy, reactionTime: avgRT);
  }

  Widget _buildShape(EFCard card) {
    Color color = _getStimulusColor(card.color);
    IconData icon = _getShapeIcon(card.shape);
    return Container(padding: const EdgeInsets.all(8), child: Icon(icon, size: 70 * card.size.clamp(1.0, 1.5), color: color));
  }

  Color _getStimulusColor(StimulusColor color) {
    switch (color) {
      case StimulusColor.red: return Colors.red;
      case StimulusColor.blue: return Colors.blue;
      case StimulusColor.green: return Colors.green;
      case StimulusColor.yellow: return Colors.amber;
    }
  }

  IconData _getShapeIcon(StimulusShape shape) {
    switch (shape) {
      case StimulusShape.circle: return Icons.circle;
      case StimulusShape.square: return Icons.square;
      case StimulusShape.triangle: return Icons.change_history;
      case StimulusShape.star: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen('Logic Gates Challenge', 'Infer the hidden logical rule using trial-and-error. The rule shifts non-sequentially after four correct responses, testing your cognitive flexibility.');

    return Scaffold( appBar: AppBar(title: Text('Logic Gates (${remainingSeconds}s)'), backgroundColor: Colors.indigo),
      body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.indigo.withOpacity(0.05), Colors.white])),
        child: SafeArea(
          child: Column( children: [
            _buildHeader(),
            _buildFeedback(),
            const SizedBox(height: 30),

            // Current Stimulus Card
            Container( width: 150, height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]), child: _buildShape(currentCard)),
            const SizedBox(height: 20),

            Text('Which rule is ACTIVE?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 20),

            // Response Buttons (Logic Gates)
            Wrap( spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
              children: rules.map((rule) {
                Color color = rule.index == 0 ? Colors.red : rule.index == 1 ? Colors.blue : rule.index == 2 ? Colors.amber : Colors.purple;
                return _buildRuleButton(rule, ruleNames[rule.index], color);
              }).toList(),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen(String title, String description) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF5C6BC0), const Color(0xFF880E4F)])), // Custom safe colors
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.rule_folder_outlined, size: 80, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem('🎯', 'Goal', description, Colors.indigo),
                        _buildRuleItem('🤔', 'How to Play', 'Guess the active rule (Color Match, Shape Match, etc.) by tapping the corresponding button.', Colors.indigo),
                        _buildRuleItem('🔄', 'Rule Shift', 'The rule changes automatically after 4 consecutive correct answers. Adapt quickly!', Colors.indigo),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 8,),
                child: const Text('Start Game', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description, Color themeColor) {
    return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
      ]),
      ),],),
    );
  }

  Widget _buildHeader() {
    return Container(padding: const EdgeInsets.all(20.0), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatCard('Correct', '$correctTrials', Colors.green),
        _buildStatCard('Shift', '$consecutiveCorrect/4', Colors.purple),
        _buildStatCard('Time', '${remainingSeconds}s', remainingSeconds > 10 ? Colors.blue : Colors.red),
      ]),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildFeedback() {
    if (feedback == 'Infer the Rule!') return const SizedBox.shrink();
    bool isSuccess = feedback.contains('Correct') || feedback.contains('Rule Changed');
    return AnimatedBuilder(animation: _feedbackController, builder: (context, child) {
      return Transform.scale(scale: 1.0 + (_feedbackController.value * 0.1),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20), border: Border.all(color: isSuccess ? Colors.green : Colors.red, width: 2,),
          ),
          child: Text(feedback, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSuccess ? Colors.green : Colors.red)),
        ),
      );
    },
    );
  }

  Widget _buildRuleButton(LogicalRule rule, String name, Color color) {
    return GestureDetector(
      onTap: () => _onCategoryTap(rule),
      child: Container(
        width: 150, height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
        ),
        child: Center(
          child: Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 12. LABYRINTH PLANNER (FIXED: Enables Path Tracing)
// --------------------------------------------------------------------------

class LabyrinthPlannerGame extends StatefulWidget {
  final GameEngine gameEngine;
  const LabyrinthPlannerGame({super.key, required this.gameEngine});
  @override
  State<LabyrinthPlannerGame> createState() => _LabyrinthPlannerGameState();
}

class _LabyrinthPlannerGameState extends State<LabyrinthPlannerGame> {
  // State variables for Labyrinth Planning
  final int gridSize = 5;
  final double cellSize = 60.0;
  List<List<bool>> walls = [];
  Offset start = const Offset(0, 0);
  Offset end = Offset((5 - 1).toDouble(), (5 - 1).toDouble()); // Initialize end based on gridSize
  List<Offset> plannedPath = [];
  bool planningMode = true;
  int optimalMoves = 0;
  double planningTimeMs = 0.0;
  Timer? gameTimer;
  int remainingSeconds = 60;
  Stopwatch planningStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    planningStopwatch.stop();
    super.dispose();
  }

  void _initializeGame() {
    _generateLabyrinth();
    planningStopwatch.start();
  }

  void _startGame() {
    setState(() {
      gameTimer?.cancel();
      remainingSeconds = 60;
      planningMode = true;
    });
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() { remainingSeconds--; if (remainingSeconds <= 0) _endGame(); });
    });
  }

  void _generateLabyrinth() {
    final random = Random();
    walls = List.generate(gridSize, (_) => List.generate(gridSize, (_) => random.nextDouble() < 0.25));
    // Ensure start/end are open
    walls[start.dy.toInt()][start.dx.toInt()] = false;
    walls[end.dy.toInt()][end.dx.toInt()] = false;
    optimalMoves = 8 + random.nextInt(3);
    plannedPath = [start];
  }

  // FIX: Simplified and corrected path tracing logic
// CORRECTED PATH TRACING LOGIC
  void _onCellTap(Offset cell) {
    // 1. Basic checks (if not planning or cell is out of bounds/wall)
    if (!planningMode || cell.dx.toInt() < 0 || cell.dx.toInt() >= gridSize || cell.dy.toInt() < 0 || cell.dy.toInt() >= gridSize) return;
    if (walls[cell.dy.toInt()][cell.dx.toInt()]) return; // Do nothing if it's a wall

    final Offset lastCell = plannedPath.last;
    final int pathLength = plannedPath.length;

    // 2. Check 1: Backtracking (Tapping the cell immediately preceding the last cell)
    // This must be checked BEFORE attempting to add a new step.
    if (pathLength >= 2 && cell == plannedPath[pathLength - 2]) {
      setState(() {
        plannedPath.removeLast(); // Successfully backtrack
      });
      return;
    }

    // 3. Check 2: Forward Movement (Tapping a new, adjacent, valid cell)
    // If the cell is not already in the path (or is the start/end), and it's a valid next step.
    if (_isValidNextStep(cell)) {
      setState(() {
        plannedPath.add(cell);
      });
      if (cell == end) {
        _startExecutionPhase();
      }
    }

    // 4. Case: Tapping the current cell or a non-adjacent cell is ignored.
  }

// NOTE: The _isValidNextStep method is correct for checking adjacency and walls.

  bool _isValidNextStep(Offset next) {
    Offset current = plannedPath.last;
    // Wall Check
    if (walls[next.dy.toInt()][next.dx.toInt()]) return false;

    // Adjacency Check (Manhattan distance = 1)
    int dx = (current.dx - next.dx).abs().toInt();
    int dy = (current.dy - next.dy).abs().toInt();
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  void _startExecutionPhase() {
    planningStopwatch.stop(); gameTimer?.cancel();
    planningTimeMs = planningStopwatch.elapsedMilliseconds.toDouble();
    double currentPathLength = (plannedPath.length - 1).toDouble().clamp(1.0, double.infinity);

    double efficiencyScore = (optimalMoves / currentPathLength).clamp(0.0, 1.0) * 3;
    double speedScore = (60000.0 / planningTimeMs).clamp(0.0, 1.0) * 2;
    double finalScore = (efficiencyScore + speedScore).clamp(0.0, 5.0);
    double accuracy = (optimalMoves / currentPathLength).clamp(0.0, 1.0) * 100;

    widget.gameEngine.completeGame(score: finalScore, accuracy: accuracy, reactionTime: planningTimeMs);
  }

  void _endGame() {
    gameTimer?.cancel();
    if (planningStopwatch.isRunning) planningStopwatch.stop();
    planningTimeMs = planningStopwatch.elapsedMilliseconds.toDouble();
    double currentPathLength = (plannedPath.length > 1 ? plannedPath.length - 1 : 1).toDouble();

    double efficiencyScore = (optimalMoves / currentPathLength).clamp(0.0, 1.0) * 3;
    double speedScore = (60000.0 / planningTimeMs).clamp(0.0, 1.0) * 2;
    double finalScore = (efficiencyScore + speedScore).clamp(0.0, 5.0);
    double accuracy = (optimalMoves / currentPathLength).clamp(0.0, 1.0) * 100;

    widget.gameEngine.completeGame(score: finalScore, accuracy: accuracy, reactionTime: planningTimeMs);
  }

  @override
  Widget build(BuildContext context) {
    if (!planningStopwatch.isRunning && !planningMode) return _buildRulesScreen('Labyrinth Planner', 'Mentally plan the most efficient path through the maze. The clock measures your planning time before you submit the final path.');

    return Scaffold(appBar: AppBar(title: Text('Labyrinth Planner (${remainingSeconds}s)'), backgroundColor: Colors.teal),
      body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.withOpacity(0.05), Colors.white])),
        child: SafeArea(
          child: Column( children: [
            _buildHeader(),
            _buildPlanningArea(),
            // Submit Button
            if (planningMode)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  onPressed: plannedPath.last == end ? _startExecutionPhase : null,
                  icon: const Icon(Icons.check_circle),
                  label: Text(plannedPath.last == end ? 'Submit Path' : 'Finish Path to Submit'),
                  style: ElevatedButton.styleFrom(backgroundColor: plannedPath.last == end ? Colors.green : Colors.grey, elevation: 8),
                ),
              )
          ],
          ),
        ),
      ),
    );
  }

  // ... (Rest of the helper methods for LabyrinthPlannerGame and LabyrinthPathPainter are unchanged) ...

  Widget _buildRulesScreen(String title, String description) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF00BFA5), const Color(0xFF00838F)])), // Custom safe colors
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.alt_route_outlined, size: 80, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem('🎯', 'Goal', description, Colors.teal),
                        _buildRuleItem('⏱️', 'Planning Time', 'Trace your path from Start (Green) to End (Red). The clock measures your total planning time.', Colors.teal),
                        _buildRuleItem('📏', 'Rules', 'You can only move one step horizontally or vertically and cannot pass through walls (Black).', Colors.teal),
                        _buildRuleItem('🎖️', 'Scoring', 'Score is based on planning speed and path efficiency (moves vs optimal).', Colors.teal),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 8,),
                child: const Text('Start Game', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description, Color themeColor) {
    return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
      ]),
      ),],),
    );
  }

  Widget _buildHeader() {
    return Container(padding: const EdgeInsets.all(20.0), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatCard('Moves', '${plannedPath.length - 1}', Colors.blue),
        _buildStatCard('Optimal', '$optimalMoves', Colors.amber),
        _buildStatCard('Time', '${(planningStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s', planningStopwatch.isRunning ? Colors.teal : Colors.green),
      ]),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildPlanningArea() {
    return Expanded(
      child: Center(
        child: Container(
          width: gridSize * cellSize, height: gridSize * cellSize,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15)],
          ),
          child: CustomPaint(
            painter: LabyrinthPathPainter(walls, start, end, plannedPath, cellSize),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) {
                int row = index ~/ gridSize;
                int col = index % gridSize;
                Offset cell = Offset(col.toDouble(), row.toDouble());

                return GestureDetector(
                  onTap: () => _onCellTap(cell),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200, width: 0.5),
                      color: walls[row][col] ? Colors.black26 : Colors.transparent,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class LabyrinthPathPainter extends CustomPainter {
  final List<List<bool>> walls;
  final Offset start;
  final Offset end;
  final List<Offset> path;
  final double cellSize;

  LabyrinthPathPainter(this.walls, this.start, this.end, this.path, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Path
    final pathPaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final pathLine = Path();
    for (int i = 0; i < path.length; i++) {
      Offset cell = path[i];
      // Calculation requires cellSize (double)
      Offset center = Offset(cell.dx * cellSize + cellSize / 2, cell.dy * cellSize + cellSize / 2);
      if (i == 0) {
        pathLine.moveTo(center.dx, center.dy);
      } else {
        pathLine.lineTo(center.dx, center.dy);
      }
    }
    canvas.drawPath(pathLine, pathPaint);

    // 2. Draw Start/End Markers
    final startPaint = Paint()..color = Colors.green;
    final endPaint = Paint()..color = Colors.red;

    Offset startCenter = Offset(start.dx * cellSize + cellSize / 2, start.dy * cellSize + cellSize / 2);
    Offset endCenter = Offset(end.dx * cellSize + cellSize / 2, end.dy * cellSize + cellSize / 2);

    canvas.drawCircle(startCenter, 15, startPaint);
    canvas.drawCircle(endCenter, 15, endPaint);

    // 3. Draw current position marker
    if (path.isNotEmpty) {
      Offset currentCenter = Offset(path.last.dx * cellSize + cellSize / 2, path.last.dy * cellSize + cellSize / 2);
      final currentPaint = Paint()..color = Colors.blue.shade700;
      canvas.drawCircle(currentCenter, 10, currentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LabyrinthPathPainter oldDelegate) {
    return oldDelegate.path != path;
  }
}

// --------------------------------------------------------------------------
// 13. GO/NO-GO EXTREME (Inhibitory Control, Sustained Attention)
// --------------------------------------------------------------------------

class GoNoGoExtremeGame extends StatefulWidget {
  final GameEngine gameEngine;
  const GoNoGoExtremeGame({super.key, required this.gameEngine});
  @override
  State<GoNoGoExtremeGame> createState() => _GoNoGoExtremeGameState();
}

class _GoNoGoExtremeGameState extends State<GoNoGoExtremeGame> with SingleTickerProviderStateMixin {
  final String goStimulus = 'O';
  final String noGoStimulus = 'X';
  String currentStimulus = '';
  bool isGoTrial = true;
  bool stimulusVisible = false;
  bool responded = false;

  int totalTrials = 0;
  int hits = 0; // Correct Go response
  int falseAlarms = 0; // Incorrect No-Go response (Tapping X)
  int misses = 0; // Incorrect Go response (Missing O)

  Timer? gameTimer;
  int remainingSeconds = 60;
  Stopwatch trialStopwatch = Stopwatch();
  List<int> reactionTimes = [];

  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _flashController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          remainingSeconds--;
          if (remainingSeconds <= 0) _endGame();
        });
      });
      _startNextTrial();
    });
  }

  void _startNextTrial() {
    if (remainingSeconds <= 0) return;

    // High Go ratio: 75% Go, 25% No-Go
    final random = Random();
    isGoTrial = random.nextDouble() < 0.75;

    setState(() {
      currentStimulus = isGoTrial ? goStimulus : noGoStimulus;
      stimulusVisible = true;
      responded = false;
      totalTrials++;
    });

    trialStopwatch.reset();
    trialStopwatch.start();
    _flashController.forward();

    // Stimulus duration (Adaptive difficulty uses 500ms default)
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (stimulusVisible && !responded && isGoTrial) {
        // Missed Go Trial
        setState(() => misses++);
      }

      setState(() => stimulusVisible = false);
      _flashController.reverse();

      // Inter-stimulus interval (Adaptive difficulty uses 1000ms default)
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted && remainingSeconds > 0) _startNextTrial();
      });
    });
  }

  void _onScreenTap() {
    if (!stimulusVisible || responded || remainingSeconds <= 0) return;

    responded = true;
    trialStopwatch.stop();
    int reactionTime = trialStopwatch.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    // FIX: Declare and initialize isCorrect here.
    bool isCorrect;

    // Determine the result logic first
    if (isGoTrial) {
      // Correct Go response (Hit) - isCorrect is TRUE if it's a Hit
      isCorrect = true;
    } else {
      // Incorrect No-Go response (False Alarm) - isCorrect is FALSE if it's a False Alarm
      isCorrect = false;
    }

    setState(() {
      if (isGoTrial) {
        // Correct Go response (Hit)
        hits++;
        HapticFeedback.mediumImpact();
      } else {
        // Incorrect No-Go response (False Alarm)
        falseAlarms++;
        HapticFeedback.heavyImpact();
      }
    });

    // CRITICAL: Call recordTrial using the guaranteed assigned value.
    widget.gameEngine.recordTrial(isCorrect, reactionTime);
  }

  void _endGame() {
    gameTimer?.cancel();
    trialStopwatch.stop();

    int totalGo = hits + misses;
    int totalNoGo = totalTrials - totalGo;

    double hitRate = totalGo > 0 ? (hits / totalGo) : 0;
    double falseAlarmRate = totalNoGo > 0 ? (falseAlarms / totalNoGo) : 0;

    double avgRT = reactionTimes.isEmpty ? 1000.0 : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // Score (0-5): Focus on inhibition (False Alarms) and detection (Hits)
    double accuracy = (hitRate * 100).clamp(0.0, 100.0);
    double inhibitionScore = (1.0 - falseAlarmRate).clamp(0.0, 1.0) * 3; // Max 3 points for low False Alarms
    double detectionScore = hitRate.clamp(0.0, 1.0) * 2; // Max 2 points for high Hits
    double finalScore = (inhibitionScore + detectionScore).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: avgRT,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (totalTrials == 0 && remainingSeconds == 60) return _buildRulesScreen('Go/No-Go Extreme', 'Respond only to the "Go" stimulus (O) and suppress your response to the "No-Go" stimulus (X). The high ratio of Go trials makes inhibition difficult.');

    return GestureDetector(
      onTap: _onScreenTap,
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.05), Colors.deepPurple.withOpacity(0.05)])),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _flashController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: stimulusVisible ? 1.0 : 0.0,
                        child: Transform.scale(
                          scale: 1.0 + (_flashController.value * 0.1),
                          child: Container(
                            width: 200, height: 200,
                            decoration: BoxDecoration(
                              color: isGoTrial ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: (isGoTrial ? Colors.green : Colors.red).withOpacity(0.5), blurRadius: 20)],
                            ),
                            child: Center(
                              child: Text(currentStimulus, style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: Colors.white)),
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
                child: Text(
                  'Tap anywhere ONLY when you see the "O" stimulus.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen(String title, String description) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF9C27B0), const Color(0xFF4A148C)])), // Custom safe colors
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.pan_tool_outlined, size: 80, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem('🎯', 'Goal', description),
                        _buildRuleItem('GO (O)', 'The Green Circle', 'Tap as fast as possible when the green "O" appears.'),
                        _buildRuleItem('NO-GO (X)', 'The Red Circle', 'DO NOT tap the screen when the red "X" appears. Suppress your response!'),
                        _buildRuleItem('🎖️', 'Scoring', 'Score is heavily penalized by False Alarms (tapping X) and rewarded for fast Hits (tapping O).'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 8,),
                child: const Text('Start Test', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
      ]),
      ),],),
    );
  }

  Widget _buildHeader() {
    double falseAlarmRate = totalTrials > 0 ? (falseAlarms / totalTrials * 100) : 0;
    return Container(padding: const EdgeInsets.all(16.0), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatCard('Trials', '$totalTrials', Colors.blue),
        _buildStatCard('Hits', '$hits', Colors.green),
        _buildStatCard('False Alarms', '$falseAlarms', Colors.red),
        _buildStatCard('Inhibition', '${(100.0 - falseAlarmRate).toStringAsFixed(0)}%', Colors.purple),
      ]),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}


// --------------------------------------------------------------------------
// 14. CATEGORY SWITCH TASK (REWRITTEN: Fixes Score/Logic & Tests Set Switching)
// --------------------------------------------------------------------------
// --------------------------------------------------------------------------
// 14. CATEGORY SWITCH TASK (Cognitive Flexibility, Set Shifting)
// --------------------------------------------------------------------------

class CategorySwitchGame extends StatefulWidget {
  final GameEngine gameEngine;
  const CategorySwitchGame({super.key, required this.gameEngine});
  @override
  State<CategorySwitchGame> createState() => _CategorySwitchGameState();
}

class _CategorySwitchGameState extends State<CategorySwitchGame> with SingleTickerProviderStateMixin {
  final List<CardProperty> properties = [CardProperty.color, CardProperty.shape, CardProperty.number];
  CardProperty currentRule = CardProperty.color;
  EFCard currentCard = EFCard(color: StimulusColor.red, shape: StimulusShape.circle, number: 1, size: 1.0);

  // FIX 1: Cue is clear rule. Buttons represent values (Red, Square, One).
  String cueText = 'Match COLOR';
  // List of values corresponding to the buttons the user sees.
  List<String> targetValues = ['RED', 'SQUARE', 'ONE'];

  int totalTrials = 0;
  int correctTrials = 0;
  int errors = 0;

  Timer? gameTimer;
  int remainingSeconds = 60;
  Stopwatch trialStopwatch = Stopwatch();
  List<int> reactionTimes = [];

  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _initializeGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // Start with Color rule, then switch immediately on first trial
    currentRule = CardProperty.number;
    _generateCard();
  }

  void _startGame() {
    setState(() {
      // FIX 2: Start the timer separately from the trial flow
      gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          remainingSeconds--;
          if (remainingSeconds <= 0) _endGame();
        });
      });
      _startNextTrial();
    });
  }

  void _startNextTrial() {
    // Switches the rule in a rotating order (Number -> Color -> Shape -> Number)
    int nextIndex = (properties.indexOf(currentRule) + 1) % properties.length;
    currentRule = properties[nextIndex];

    _generateCard();

    // Determine the required target values for the buttons based on the current card
    _updateTargetValues();

    cueText = 'Match ${currentRule.name.toUpperCase()}';

    setState(() {
      trialStopwatch.reset();
      trialStopwatch.start();
    });
  }

  // FIX 3: Utility to get the string representation of the card's value based on the rule
  String _getCardValue(EFCard card, CardProperty rule) {
    switch (rule) {
      case CardProperty.color:
        return card.color.name.toUpperCase();
      case CardProperty.shape:
        return card.shape.name.toUpperCase();
      case CardProperty.number:
        return card.number.toString();
      default:
        return '';
    }
  }

  void _updateTargetValues() {
    // Use the three core properties (Color/Shape/Number) for the buttons
    targetValues = [
      currentCard.color.name.toUpperCase(),
      _getShapeIcon(currentCard.shape).codePoint.toString(), // Needs unique ID for shape/number buttons
      currentCard.number.toString()
    ];
    // This part is tricky without knowing the exact button representation (values vs rules)
    // STICKING TO THE ORIGINAL SIMPLIFICATION: Buttons are named "COLOR", "SHAPE", "NUMBER"
    // The user taps the button that represents the correct *value* of the active category on the card.

    // For this rewrite, we assume the buttons are hardcoded to the RULES (Color/Shape/Number)
    // and the user must tap the correct rule button based on the *current card's state*.
  }


  void _onCategoryTap(CardProperty tappedProperty) {
    if (remainingSeconds <= 0) return;

    totalTrials++;
    trialStopwatch.stop();
    int reactionTime = trialStopwatch.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    // CRITICAL FIX 4: The check is: Does the tapped button *match* the active rule?
    bool isCorrect = (tappedProperty == currentRule);

    setState(() {
      if (isCorrect) {
        correctTrials++;
        _feedbackController.forward().then((_) => _feedbackController.reverse());
        HapticFeedback.lightImpact();
      } else {
        errors++;
        _feedbackController.forward().then((_) => _feedbackController.reverse());
        HapticFeedback.heavyImpact();
      }
    });
    widget.gameEngine.recordTrial(isCorrect, reactionTime);

    // Start next trial immediately
    Timer(const Duration(milliseconds: 500), () {
      if (mounted && remainingSeconds > 0) _startNextTrial();
    });
  }

  void _endGame() {
    gameTimer?.cancel();
    trialStopwatch.stop();

    double accuracy = totalTrials > 0 ? (correctTrials / totalTrials * 100) : 0;
    double avgRT = reactionTimes.isEmpty ? 1000.0 : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // Target RT = 750ms.
    double targetRT = 750.0;
    double speedFactor = (targetRT / avgRT).clamp(0.0, 1.0);
    double speedReward = speedFactor * 2.0;

    double accuracyFactor = (accuracy / 100) * 3.0;
    double finalScore = (accuracyFactor + speedReward).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: avgRT,
    );
  }

  // --- Helper Methods (Reused from LogicGates/EFCard context) ---

  void _generateCard() {
    final random = Random();
    currentCard = EFCard(
      color: StimulusColor.values[random.nextInt(StimulusColor.values.length)],
      shape: StimulusShape.values[random.nextInt(StimulusShape.values.length)],
      number: random.nextInt(3) + 1,
      size: 1.0,
    );
  }

  Color _getStimulusColor(StimulusColor color) {
    switch (color) {
      case StimulusColor.red: return Colors.red;
      case StimulusColor.blue: return Colors.blue;
      case StimulusColor.green: return Colors.green;
      case StimulusColor.yellow: return Colors.amber;
    }
  }

  IconData _getShapeIcon(StimulusShape shape) {
    switch (shape) {
      case StimulusShape.circle: return Icons.circle;
      case StimulusShape.square: return Icons.square;
      case StimulusShape.triangle: return Icons.change_history;
      case StimulusShape.star: return Icons.star;
    }
  }

  Widget _buildShape(EFCard card, Color color) {
    IconData icon = _getShapeIcon(card.shape);
    return Container(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 70 * card.size.clamp(1.0, 1.5), color: color),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (totalTrials == 0 && remainingSeconds == 60) return _buildRulesScreen('Category Switch Task', 'Identify the active rule and tap the button corresponding to that rule. The rule changes every trial!');

    Color cardColor = _getStimulusColor(currentCard.color);

    return Scaffold( appBar: AppBar(title: Text('Category Switch (${remainingSeconds}s)'), backgroundColor: Colors.lightGreen),
      body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.lightGreen.withOpacity(0.05), Colors.white])),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFeedback(),
              const SizedBox(height: 30),

              // Rule Cue (The target category that must be matched)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.lightGreen, width: 2),
                ),
                child: Text(cueText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.lightGreen)),
              ),
              const SizedBox(height: 20),

              // Current Stimulus Card (The object the user must categorize)
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildShape(currentCard, cardColor),
                    Text('${currentCard.number}', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Tap the button for the ACTIVE category:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 20),

              // Response Buttons (Categories: Color, Shape, Number)
              Wrap(
                spacing: 12, runSpacing: 12,
                alignment: WrapAlignment.center,
                children: properties.map((prop) {
                  return _buildRuleButton(prop, prop.name);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen(String title, String description) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFAEEA00), const Color(0xFF33691E)])),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.switch_access_shortcut_outlined, size: 80, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem('🎯', 'Goal', description, Colors.lightGreen),
                        _buildRuleItem('📝', 'Active Rule', 'The required matching category (Color, Shape, or Number) is written at the top. This changes every trial!', Colors.lightGreen),
                        // FIX: Rule is simplified to: Tap the category that is currently active.
                        _buildRuleItem('👆', 'Action', 'Tap the button that names the current active category (e.g., tap COLOR if the cue is "Match COLOR").', Colors.lightGreen),
                        _buildRuleItem('⏱️', 'Speed', 'Speed and accuracy are crucial for a high score.', Colors.lightGreen),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 8,),
                child: const Text('Start Game', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description, Color themeColor) {
    return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
      ]),
      ),],),
    );
  }

  Widget _buildHeader() {
    return Container(padding: const EdgeInsets.all(20.0), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatCard('Correct', '$correctTrials', Colors.green),
        _buildStatCard('Errors', '$errors', Colors.red),
        _buildStatCard('Time', '${remainingSeconds}s', remainingSeconds > 10 ? Colors.lightGreen : Colors.red),
      ]),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildFeedback() {
    if (totalTrials == 0) return const SizedBox.shrink();
    bool isCorrect = totalTrials == correctTrials; // Simplified feedback check

    return AnimatedBuilder(animation: _feedbackController, builder: (context, child) {
      return Transform.scale(scale: 1.0 + (_feedbackController.value * 0.1),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20), border: Border.all(color: isCorrect ? Colors.green : Colors.red, width: 2,),
          ),
          child: Text(isCorrect ? '✓ Correct Switch!' : '✗ Incorrect Switch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isCorrect ? Colors.green : Colors.red)),
        ),
      );
    },
    );
  }

  Widget _buildRuleButton(CardProperty prop, String name) {
    // Buttons are styled based on their meaning (Color, Shape, Number)
    Color color = prop == CardProperty.color ? Colors.red : prop == CardProperty.shape ? Colors.blue : Colors.amber;

    return GestureDetector(
      onTap: () => _onCategoryTap(prop),
      child: Container(
        width: 100, height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
        ),
        child: Center(
          child: Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }
}


// --------------------------------------------------------------------------
// 15. REVERSE STROOP (Set Maintenance, Inhibition)
// --------------------------------------------------------------------------

class ReverseStroopGame extends StatefulWidget {
  final GameEngine gameEngine;
  const ReverseStroopGame({super.key, required this.gameEngine});
  @override
  State<ReverseStroopGame> createState() => _ReverseStroopGameState();
}

class _ReverseStroopGameState extends State<ReverseStroopGame> with SingleTickerProviderStateMixin {
  final List<String> colorWords = ['RED', 'BLUE', 'GREEN', 'YELLOW'];
  final List<Color> inkColors = [Colors.red, Colors.blue, Colors.green, Colors.amber];

  String currentWord = '';
  Color currentInk = Colors.red;

  int totalTrials = 0;
  int correctTrials = 0;
  int errors = 0;

  Timer? gameTimer;
  int remainingSeconds = 60;
  Stopwatch trialStopwatch = Stopwatch();
  List<int> reactionTimes = [];

  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          remainingSeconds--;
          if (remainingSeconds <= 0) _endGame();
        });
      });
      _startNextTrial();
    });
  }

  void _startNextTrial() {
    final random = Random();

    // Choose a random word and a conflicting ink color
    currentWord = colorWords[random.nextInt(colorWords.length)];
    Color conflictingInk;
    do {
      conflictingInk = inkColors[random.nextInt(inkColors.length)];
    } while (currentWord == _getColorName(conflictingInk)); // Ensure it's incongruent (like the original task)

    currentInk = conflictingInk;

    setState(() {
      trialStopwatch.reset();
      trialStopwatch.start();
    });
  }

  void _onWordTap(String tappedWord) {
    if (remainingSeconds <= 0) return;

    totalTrials++;
    int reactionTime = trialStopwatch.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    // In Reverse Stroop, the correct answer is the WORD's MEANING, not the INK COLOR.
    bool isCorrect = tappedWord == currentWord;

    setState(() {
      if (isCorrect) {
        correctTrials++;
        _feedbackController.forward().then((_) => _feedbackController.reverse());
        HapticFeedback.lightImpact();
      } else {
        errors++;
        _feedbackController.forward().then((_) => _feedbackController.reverse());
        HapticFeedback.heavyImpact();
      }
    });
    widget.gameEngine.recordTrial(isCorrect, reactionTime);

    // Start next trial immediately
    Timer(const Duration(milliseconds: 500), () {
      if (mounted && remainingSeconds > 0) _startNextTrial();
    });
  }

  void _endGame() {
    gameTimer?.cancel();
    trialStopwatch.stop();

    double accuracy = totalTrials > 0 ? (correctTrials / totalTrials * 100) : 0;
    double avgRT = reactionTimes.isEmpty ? 1000.0 : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // Score (0-5): Focus on speed and inhibition accuracy
    double finalScore = ((accuracy / 100) * 3 + (2000.0 / avgRT).clamp(0.0, 2.0)).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: avgRT,
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return 'RED';
    if (color == Colors.blue) return 'BLUE';
    if (color == Colors.green) return 'GREEN';
    if (color == Colors.amber) return 'YELLOW';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (totalTrials == 0 && remainingSeconds == 60) return _buildRulesScreen('Reverse Stroop Test', 'Tap the button that matches the WORD\'S MEANING, ignoring the ink color it is printed in. This is the opposite of the classic Stroop task, testing set maintenance.');

    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.pink.withOpacity(0.05), Colors.red.withOpacity(0.05)])),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFeedback(),
            const SizedBox(height: 50),

            // Current Stimulus Word (Incongruent Ink)
            Container(
              width: 250, height: 100,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
              ),
              child: Center(
                child: Text(
                  currentWord,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: currentInk, // The conflicting ink color
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Text('Tap the button that matches the word:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 20),

            // Response Buttons (Word Meanings)
            Wrap(
              spacing: 12, runSpacing: 12,
              alignment: WrapAlignment.center,
              children: colorWords.map((word) {
                return _buildWordButton(word);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesScreen(String title, String description) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFC2185B), const Color(0xFFE53935)])), // Custom safe colors
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.invert_colors_on_outlined, size: 80, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem('🎯', 'Goal', description),
                        _buildRuleItem('🧠', 'The Conflict', 'The word\'s meaning will conflict with the color it is printed in (e.g., the word "RED" in blue ink).'),
                        _buildRuleItem('👆', 'Action', 'Your task is to ignore the INK color and tap the button that matches the WORD\'S MEANING.'),
                        _buildRuleItem('⏱️', 'Speed', 'Speed and accuracy under this high cognitive conflict are measured.'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 8,),
                child: const Text('Start Test', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String title, String description) {
    return Padding(padding: const EdgeInsets.only(bottom: 20.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
      ]),
      ),],),
    );
  }

  Widget _buildHeader() {
    return Container(padding: const EdgeInsets.all(20.0), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatCard('Correct', '$correctTrials', Colors.green),
        _buildStatCard('Errors', '$errors', Colors.red),
        _buildStatCard('Time', '${remainingSeconds}s', remainingSeconds > 10 ? Colors.pink : Colors.red),
      ]),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildFeedback() {
    if (totalTrials == 0) return const SizedBox.shrink();
    bool isCorrect = totalTrials == correctTrials;

    return AnimatedBuilder(animation: _feedbackController, builder: (context, child) {
      return Transform.scale(scale: 1.0 + (_feedbackController.value * 0.1),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20), border: Border.all(color: isCorrect ? Colors.green : Colors.red, width: 2,),
          ),
          child: Text(isCorrect ? '✓ Correct Meaning!' : '✗ Inhibition Failure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isCorrect ? Colors.green : Colors.red)),
        ),
      );
    },
    );
  }

  Widget _buildWordButton(String word) {
    Color color = inkColors[colorWords.indexOf(word)];

    return GestureDetector(
      onTap: () => _onWordTap(word),
      child: Container(
        width: 150, height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
        ),
        child: Center(
          child: Text(word, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// HELPER ENUMS AND DATA MODELS (WM & ATT Games)
// --------------------------------------------------------------------------

enum AttentionTaskType { go, noGo }
enum FlankerDirection { left, right }

class Sentence {
  final String text;
  final String lastWord;
  final bool isCorrect;
  Sentence(this.text, this.lastWord, this.isCorrect);
}

// --------------------------------------------------------------------------
// WORKING MEMORY GAMES (IDs 16-20)
// --------------------------------------------------------------------------

// 16. DUAL N-BACK GAME (Working Memory - ID 16)
class DualNBackGame extends StatefulWidget {
  final GameEngine gameEngine;
  const DualNBackGame({super.key, required this.gameEngine});
  @override
  State<DualNBackGame> createState() => _DualNBackGameState();
}

class _DualNBackGameState extends State<DualNBackGame> with SingleTickerProviderStateMixin {
  int nBack = 2; // Adaptive difficulty changes this (2-back default)
  final int gridSize = 3;
  int currentPos = -1;
  String currentLetter = '';

  // FIX: responded tracks if the user tapped during the current trial interval.
  bool responded = false;

  List<int> posHistory = [];
  List<String> letterHistory = [];

  int totalTrials = 0;
  int correctMatches = 0;
  int missedMatches = 0;

  bool matchPos = false;
  bool matchLetter = false;
  bool gameStarted = false;

  Timer? trialTimer;
  int remainingSeconds = 60;
  final Duration trialDuration = const Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    // If game has started (e.g., loaded from a running state), run the start method
    // Otherwise, the build method shows the rules screen.
    if (gameStarted) _startGame();
  }

  @override
  void dispose() {
    trialTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 60;
      posHistory = [];
      letterHistory = [];
      totalTrials = 0;
      correctMatches = 0;
      missedMatches = 0;
      nBack = 2; // Reset N to start difficulty

      trialTimer?.cancel();
      trialTimer = Timer.periodic(trialDuration, (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (remainingSeconds <= 0) {
          _endGame();
          timer.cancel();
          return;
        }
        setState(() => remainingSeconds--);
        _runTrial();
      });
      _runTrial(); // Run first trial immediately
    });
  }

  void _runTrial() {
    final random = Random();
    totalTrials++;
    setState(() => responded = false); // Reset response flag

    // 30% chance for a match in either modality
    bool shouldMatchPos = random.nextDouble() < 0.3;
    bool shouldMatchLetter = random.nextDouble() < 0.3;

    // 1. Generate position (0-8)
    int newPos;
    if (posHistory.length >= nBack && shouldMatchPos) {
      newPos = posHistory[posHistory.length - nBack];
    } else {
      do { newPos = random.nextInt(gridSize * gridSize); } while (posHistory.isNotEmpty && newPos == posHistory.last);
    }

    // 2. Generate letter (A-I)
    String newLetter;
    if (letterHistory.length >= nBack && shouldMatchLetter) {
      newLetter = letterHistory[letterHistory.length - nBack];
    } else {
      do { newLetter = String.fromCharCode('A'.codeUnitAt(0) + random.nextInt(gridSize * gridSize)); } while (letterHistory.isNotEmpty && newLetter == letterHistory.last);
    }

    setState(() {
      currentPos = newPos;
      currentLetter = newLetter;
      matchPos = (posHistory.length >= nBack) && (newPos == posHistory[posHistory.length - nBack]);
      matchLetter = (letterHistory.length >= nBack) && (newLetter == letterHistory[letterHistory.length - nBack]);
    });

    posHistory.add(newPos);
    letterHistory.add(newLetter);
  }

  void _onResponseTap(bool isSpatial) {
    if (totalTrials <= nBack || responded) return;

    setState(() => responded = true);

    bool targetMatch = isSpatial ? matchPos : matchLetter;
    bool isCorrectResponse;

    if (targetMatch) {
      // Correct Match (Hit)
      setState(() => correctMatches++);
      isCorrectResponse = true;
      HapticFeedback.mediumImpact();
    } else {
      // False Alarm (Pressed when no match occurred)
      setState(() => missedMatches++);
      isCorrectResponse = false;
      HapticFeedback.heavyImpact();
    }

    widget.gameEngine.recordTrial(isCorrectResponse, 500); // Simplified RT
  }

  void _endGame() {
    trialTimer?.cancel();

    // Total targets is an estimate (Total trials * target frequency)
    double totalTargets = totalTrials * 0.3 * 2;
    double accuracy = (correctMatches / totalTargets).clamp(0.0, 1.0) * 100;

    // Reward for complexity (N-back level)
    double nBackBonus = (nBack - 2).clamp(0, double.infinity) * 0.5;
    double finalScore = ((accuracy / 100) * 4.0 + nBackBonus).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore, accuracy: accuracy, reactionTime: trialDuration.inMilliseconds.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();

    return Scaffold(
      appBar: AppBar(title: Text('Dual N-Back (N=$nBack | ${remainingSeconds}s)'), backgroundColor: Colors.indigo.shade600),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.indigo.withOpacity(0.05), Colors.white])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('N = $nBack', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 20),

              // Spatial Grid
              SizedBox(
                width: gridSize * 80.0, height: gridSize * 80.0,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, index) {
                    bool isCurrent = index == currentPos;
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.blue.shade200 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isCurrent ? Colors.blue : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: isCurrent ? Text(currentLetter, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue.shade800)) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Response Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildResponseButton('Position Match', Icons.place, () => _onResponseTap(true)),
                  const SizedBox(width: 20),
                  _buildResponseButton('Letter Match', Icons.text_fields, () => _onResponseTap(false)),
                ],
              ),
              const SizedBox(height: 40),
              Text('Matches: $correctMatches / Misses: $missedMatches', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Dual N-Back Task',
      description: 'Simultaneously monitor the position (spatial) and the letter (verbal). Press the respective button if the current stimulus matches the one N steps back.',
      rules: [
        RuleItem('N', 'The Challenge', 'N is the number of steps back you must remember. If N=2, you compare the current stimulus to the one shown two steps ago.'),
        RuleItem('👆', 'Dual Response', 'Press "Position Match" if the square is in the same location as N steps ago. Press "Letter Match" if the letter is the same as N steps ago.'),
        RuleItem('⏱️', 'Interval', 'A new stimulus appears every 1.5 seconds. Speed and sustained focus are key.'),
      ],
      onStart: _startGame, icon: Icons.compare_arrows_outlined, gradientColors: [Colors.indigo, Colors.purple], themeColor: Colors.indigo,
    );
  }

  Widget _buildResponseButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// 17. PATH REVERSAL GAME (Visuospatial Manipulation)
class PathReversalGame extends StatefulWidget {
  final GameEngine gameEngine;
  const PathReversalGame({super.key, required this.gameEngine});
  @override
  State<PathReversalGame> createState() => _PathReversalGameState();
}

class _PathReversalGameState extends State<PathReversalGame> with SingleTickerProviderStateMixin {
  final int boardSize = 5;
  final double cellSize = 60.0;
  List<int> sequence = [];
  List<int> userSequence = [];
  int sequenceLength = 4;
  bool showingSequence = true;
  bool waitingForInput = false;
  int highlightedBlock = -1;
  int highestSpan = 4;
  bool gameStarted = false; // Initialized to false

  Stopwatch timer = Stopwatch();
  List<int> reactionTimes = [];

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here. Let the build method show rules first.
  }
  @override void dispose() { timer.stop(); super.dispose(); }

  void _startGame() {
    setState(() {
      gameStarted = true; // Set to true when button pressed
      sequenceLength = 4; // Reset to base difficulty
      highestSpan = 4;
    });
    _startNewSequence();
  }

  void _startNewSequence() {
    sequence = _generateSequence(sequenceLength);
    userSequence = [];
    showingSequence = true;
    waitingForInput = false;
    _showSequence();
  }

  List<int> _generateSequence(int length) {
    final random = Random();
    List<int> seq = [];
    for (int i = 0; i < length; i++) {
      int newBlock;
      do { newBlock = random.nextInt(boardSize * boardSize); } while (seq.contains(newBlock));
      seq.add(newBlock);
    }
    return seq;
  }

  void _showSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < sequence.length; i++) {
      setState(() => highlightedBlock = sequence[i]);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => highlightedBlock = -1);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() {
      showingSequence = false;
      waitingForInput = true;
      timer.start();
    });
  }

  void _onBlockTap(int blockIndex) {
    if (!waitingForInput) return;

    setState(() {
      userSequence.add(blockIndex);
      highlightedBlock = blockIndex;
    });

    if (userSequence.length == sequence.length) {
      _checkAnswer();
    } else {
      Timer(const Duration(milliseconds: 300), () => setState(() => highlightedBlock = -1));
    }
  }

  void _checkAnswer() {
    timer.stop();

    List<int> correctReverse = sequence.reversed.toList();
    bool isCorrect = true;
    for (int i = 0; i < sequence.length; i++) {
      if (userSequence[i] != correctReverse[i]) {
        isCorrect = false;
        break;
      }
    }

    double reactionTime = timer.elapsedMilliseconds.toDouble();
    double accuracy = isCorrect ? 100.0 : 0.0;

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      setState(() => highestSpan = sequenceLength);
      sequenceLength++;
    } else {
      HapticFeedback.heavyImpact();
      sequenceLength = 4;
    }

    double spanScore = (highestSpan / 10.0).clamp(0.0, 1.0) * 4.0;
    double speedScore = (4000.0 / reactionTime).clamp(0.0, 1.0) * 1.0;
    double finalScore = (spanScore + speedScore).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(score: finalScore, accuracy: accuracy, reactionTime: reactionTime);
    Timer(const Duration(milliseconds: 800), () => _startNewSequence()); // Restart sequence flow
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();

    return Scaffold(
      appBar: AppBar(title: Text('Path Reversal (N=$sequenceLength)'), backgroundColor: Colors.orange.shade600),
      body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.05), Colors.white])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(waitingForInput ? 'Reproduce the sequence in REVERSE!' : 'Watch the sequence...'),
              const SizedBox(height: 20),

              SizedBox(
                width: boardSize * cellSize,
                height: boardSize * cellSize,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: boardSize),
                  itemCount: boardSize * boardSize,
                  itemBuilder: (context, index) {
                    bool isHighlighted = index == highlightedBlock;
                    bool isInSequence = sequence.contains(index);

                    return GestureDetector(
                      onTap: () => _onBlockTap(index),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isHighlighted ? Colors.red.shade200 : isInSequence ? Colors.grey.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isHighlighted ? Colors.red : Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            isInSequence ? '${sequence.indexOf(index) + 1}' : '',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              Text('Time: ${(timer.elapsedMilliseconds / 1000).toStringAsFixed(1)}s | Span: $highestSpan', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Path Reversal Task',
      description: 'Memorize the sequence of blocks and reproduce them in the **EXACT REVERSE ORDER**. This tests your capacity for mental manipulation.',
      rules: [
        RuleItem('N', 'The Span', 'The sequence length starts at 4 and increases after every successful reversal.'),
        RuleItem('🔄', 'Reverse Order', 'If the sequence is 1-2-3-4, you must tap 4-3-2-1.'),
        RuleItem('👆', 'Action', 'Tap the blocks in the correct reverse sequence. Errors reset the span.'),
      ],
      onStart: _startGame,
      icon: Icons.flip_outlined,
      gradientColors: [Colors.orange, Colors.deepOrange],
      themeColor: Colors.orange,
    );
  }
}

// 18. SENTENCE SPAN GAME (Verbal WM, Semantic Encoding)
class SentenceSpanGame extends StatefulWidget {
  final GameEngine gameEngine;
  const SentenceSpanGame({super.key, required this.gameEngine});
  @override
  State<SentenceSpanGame> createState() => _SentenceSpanGameState();
}

class _SentenceSpanGameState extends State<SentenceSpanGame> {
  List<Sentence> currentSentences = [];
  String userInput = '';
  int spanLength = 3;
  int currentSentenceIndex = 0;
  bool reading = true;
  bool recalling = false;
  int highestSpan = 3;
  bool gameStarted = false; // Added gameStarted flag

  final List<String> sentencePool = [
    "The clock ticked loudly.", "The dog barked happily.", "She drank milk slowly.",
    "The car drove fast.", "He read the book.", "The child laughed hard.",
  ];

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here.
  }
  @override void dispose() { super.dispose(); }

  void _startGame() {
    setState(() {
      gameStarted = true;
      spanLength = 3;
      highestSpan = 3;
    });
    _startNewSpan();
  }

  void _startNewSpan() {
    userInput = '';
    currentSentenceIndex = 0;
    reading = true;
    recalling = false;
    currentSentences = _generateSpan(spanLength);
    _readNextSentence();
  }

  List<Sentence> _generateSpan(int length) {
    final random = Random();
    List<Sentence> sentences = [];
    List<String> used = [];
    for (int i = 0; i < length; i++) {
      String newSentence;
      do { newSentence = sentencePool[random.nextInt(sentencePool.length)]; } while (used.contains(newSentence));
      used.add(newSentence);
      String lastWord = newSentence.split(' ').last.replaceAll('.', '').toLowerCase();
      sentences.add(Sentence(newSentence, lastWord, true));
    }
    return sentences;
  }

  void _readNextSentence() async {
    if (currentSentenceIndex < currentSentences.length) {
      setState(() => reading = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      setState(() { reading = false; currentSentenceIndex++; });
      // FIX: Ensure recursive call to _readNextSentence is outside setState
      _readNextSentence();
    } else {
      // FIX: Wait a moment before starting recall to let the UI settle
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => recalling = true);
    }
  }

  void _submitRecall(String input) {
    if (!recalling) return;

    String requiredWords = currentSentences.map((s) => s.lastWord).join(' ');
    String inputNormalized = input.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), ' ');

    bool success = inputNormalized.split(RegExp(r'\s+')).join(' ') == requiredWords.split(RegExp(r'\s+')).join(' ');

    _checkRecall(success);
  }

  void _checkRecall(bool success) {
    if (success) {
      HapticFeedback.mediumImpact();
      setState(() => highestSpan = spanLength);
      spanLength++;
    } else {
      HapticFeedback.heavyImpact();
    }

    double finalScore = (highestSpan / 6.0).clamp(0.0, 1.0) * 5.0;
    double accuracy = success ? 100.0 : 0.0;

    widget.gameEngine.completeGame(score: finalScore, accuracy: accuracy, reactionTime: 500);
    Timer(const Duration(milliseconds: 800), () => _startNewSpan());
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();

    return Scaffold(
      appBar: AppBar(title: Text('Sentence Span (Span: $spanLength)'), backgroundColor: Colors.purple.shade600),
      body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.05), Colors.white])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (reading)
                Text(
                  // FIX: currentSentenceIndex must be checked to avoid RangeError
                  currentSentenceIndex > 0 && currentSentenceIndex <= currentSentences.length
                      ? currentSentences[currentSentenceIndex - 1].text
                      : 'Start Sequence...',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
              else if (recalling)
                const Text('Recall the last word of each sentence:', style: TextStyle(fontSize: 20)),

              const SizedBox(height: 40),

              if (recalling)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: TextField(
                    onChanged: (value) => userInput = value,
                    decoration: InputDecoration(
                      labelText: 'Enter words (separated by space)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () => _submitRecall(userInput),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    onSubmitted: _submitRecall,
                  ),
                )
              else if (!reading && currentSentenceIndex >= currentSentences.length)
                ElevatedButton(onPressed: _startNewSpan, child: const Text('Next Span')),

              const SizedBox(height: 40),
              Text('Highest Span: $highestSpan', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Sentence Span Task',
      description: 'Memorize the last word of a sequence of sentences while processing their full meaning.',
      rules: [
        RuleItem('📝', 'Memorize', 'A sequence of sentences will be displayed one by one. Memorize only the last word of each sentence.'),
        RuleItem('🔢', 'Recall', 'After the sequence ends, type the last words you remember, separated by spaces, in the correct order.'),
        RuleItem('📈', 'Progression', 'The number of sentences (span) increases after every successful recall.'),
      ],
      onStart: _startGame,
      icon: Icons.mic_external_on_outlined,
      gradientColors: [Colors.purple, Colors.pink],
      themeColor: Colors.purple,
    );
  }
}


// 19. OBJECT LOCATION RECALL GAME (Visuospatial/Binding WM)
class ObjectLocationRecallGame extends StatefulWidget {
  final GameEngine gameEngine;
  const ObjectLocationRecallGame({super.key, required this.gameEngine});
  @override
  State<ObjectLocationRecallGame> createState() => _ObjectLocationRecallGameState();
}

class _ObjectLocationRecallGameState extends State<ObjectLocationRecallGame> {
  final themeColor = Colors.cyan;
  final List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.amber];
  final int boardSize = 4;
  final int objectCount = 4; // Reset to 4 to match color count
  final double cellSize = 60.0;

  late Map<Color, Offset> initialBindings;
  late List<Color> placementOrder;

  Color? selectedTarget;

  int correctBindings = 0;
  int placementsMade = 0;

  bool showing = true;
  bool placing = false;
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here.
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      correctBindings = 0;
      placementsMade = 0;
    });
    _startNewTrial();
  }

  void _startNewTrial() {
    _generateObjects();
    _showObjects();
  }

  void _generateObjects() {
    final random = Random();
    initialBindings = {};

    List<int> availableCells = List.generate(boardSize * boardSize, (index) => index);
    availableCells.shuffle(random);

    List<Color> shuffledColors = List.from(colors)..shuffle(random);

    placementOrder = shuffledColors.take(objectCount).toList();

    for (int i = 0; i < objectCount; i++) {
      int cellIndex = availableCells[i];
      double row = (cellIndex / boardSize).floorToDouble();
      double col = (cellIndex % boardSize).floorToDouble();
      initialBindings[placementOrder[i]] = Offset(col, row);
    }
  }

  void _showObjects() async {
    setState(() => showing = true);
    await Future.delayed(const Duration(milliseconds: 4000));
    setState(() {
      showing = false;
      placing = true;
      selectedTarget = placementOrder.first;
    });
  }

  void _onCellTap(Offset cell) {
    if (!placing || selectedTarget == null) return;

    if (initialBindings[selectedTarget] == cell) {
      correctBindings++;
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    placementsMade++;

    if (placementsMade < objectCount) {
      setState(() {
        selectedTarget = placementOrder[placementsMade];
      });
    } else {
      _checkPlacements();
    }
  }

  void _checkPlacements() {
    double accuracy = (correctBindings / objectCount) * 100;
    double finalScore = (accuracy / 100) * 5.0;

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: 500,
    );
    Timer(const Duration(milliseconds: 800), () => _startGame());
  }

  // Helper function to safely look up the color key corresponding to a cell offset
  Color? _getPlacedColor(Offset cell) {
    for (var entry in initialBindings.entries) {
      if (entry.value == cell) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();

    return Scaffold(
      // FIX: Added AppBar
      appBar: AppBar(title: const Text('Object Location Recall'), backgroundColor: themeColor),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [themeColor.withOpacity(0.05), Colors.white])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlHeader(),
              const SizedBox(height: 20),

              // The Placement Grid
              SizedBox(
                width: boardSize * cellSize, height: boardSize * cellSize,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: boardSize),
                  itemCount: boardSize * boardSize,
                  itemBuilder: (context, index) {
                    double row = (index / boardSize).floorToDouble();
                    double col = (index % boardSize).floorToDouble();
                    Offset cell = Offset(col, row);

                    Color? placedObjectColor;

                    if (showing) {
                      placedObjectColor = _getPlacedColor(cell);
                    }

                    // Display a visual cue for the cell the user is tapping during PLACING
                    bool isTargetCell = placing && selectedTarget != null && initialBindings[selectedTarget] == cell;

                    return GestureDetector(
                      onTap: () => _onCellTap(cell),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isTargetCell ? Colors.black : Colors.grey.shade300,
                              width: isTargetCell ? 3 : 1
                          ),
                        ),
                        child: Center(
                          child: placedObjectColor != null
                              ? Icon(Icons.circle, size: 40, color: placedObjectColor)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            showing ? 'Memorize the locations!' : (placing ? 'Place the ${selectedTarget == null ? "" : selectedTarget!.toString().split('.').last.toUpperCase()} object.' : 'Results...'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (placing && selectedTarget != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Current Target:", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Icon(Icons.circle, size: 30, color: selectedTarget),
              ],
            ),
          const SizedBox(height: 5),
          Text('Bindings Correct: $correctBindings / $objectCount', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Object Location Recall',
      description: 'Tests visuospatial binding memory by forcing you to recall the exact location of specific colored objects.',
      rules: [
        RuleItem('👁️', 'Memorize', 'A set of colored objects will flash on the grid for 4 seconds. Memorize which color belongs to which grid cell.'),
        RuleItem('🧠', 'Recall Order', 'The system will prompt you with the color (e.g., RED). Tap the exact cell where that object was located.'),
        RuleItem('👆', 'Action', 'You must recall the objects one by one until all objects are placed.'),
      ],
      onStart: _startGame,
      icon: Icons.place_outlined,
      gradientColors: [Colors.cyan, Colors.blueGrey],
      themeColor: Colors.cyan,
    );
  }
}

// 20. SEQUENCE REPEATER GAME (Auditory WM, Forward/Backward Span)
// Distinct from Digit Span: Uses abstract auditory stimuli (tones) instead of numerical input.
class SequenceRepeaterGame extends StatefulWidget {
  final GameEngine gameEngine;
  const SequenceRepeaterGame({super.key, required this.gameEngine});
  @override
  State<SequenceRepeaterGame> createState() => _SequenceRepeaterGameState();
}

class _SequenceRepeaterGameState extends State<SequenceRepeaterGame> {
  // Logic is highly dependent on Flutter's audio playback capabilities.
  // We simulate tone presentation using visual button highlights.

  final int toneCount = 5;
  List<int> sequence = [];
  List<int> userSequence = [];
  int sequenceLength = 3;
  bool playing = true;
  bool recording = false;
  int highlightedButton = -1;
  int highestSpan = 3;

  @override
  void initState() {
    super.initState();
    _startNewSequence();
  }

  void _startNewSequence() {
    sequence = _generateSequence(sequenceLength);
    userSequence = [];
    playing = true;
    recording = false;
    _playSequence();
  }

  List<int> _generateSequence(int length) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(toneCount));
  }

  void _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));

    for (int toneIndex in sequence) {
      setState(() => highlightedButton = toneIndex);
      // Simulate tone sound here
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => highlightedButton = -1);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      playing = false;
      recording = true;
    });
  }

  void _onButtonTap(int buttonIndex) {
    if (!recording) return;

    setState(() {
      userSequence.add(buttonIndex);
      highlightedButton = buttonIndex;
    });

    // Flash feedback
    Timer(const Duration(milliseconds: 200), () => setState(() => highlightedButton = -1));

    if (userSequence.length == sequence.length) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    bool isCorrect = true;
    for (int i = 0; i < sequence.length; i++) {
      if (userSequence[i] != sequence[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      setState(() => highestSpan = sequenceLength);
      sequenceLength++;
    }

    double finalScore = (highestSpan / 6.0).clamp(0.0, 1.0) * 5.0;

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: isCorrect ? 100.0 : 0.0,
      reactionTime: 500, // Placeholder
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildGameScreen();
  }

  Widget _buildGameScreen() {
    return Scaffold(
      body: Center(
        child : SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(playing ? 'Listening...' : (recording ? 'Reproduce the sequence!' : 'Results...'), style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 40),

              Wrap(
                spacing: 15, runSpacing: 15,
                children: List.generate(toneCount, (index) {
                  bool isHighlighted = index == highlightedButton;
                  return GestureDetector(
                    onTap: () => _onButtonTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: isHighlighted ? Colors.red : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo, width: isHighlighted ? 4 : 2),
                      ),
                      child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: 24, color: isHighlighted ? Colors.white : Colors.indigo))),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// ATTENTION GAMES (IDs 21-25)
// --------------------------------------------------------------------------

// 21. FLANKER TASK (Selective Attention, Conflict Resolution)
class FlankerTaskGame extends StatefulWidget {
  final GameEngine gameEngine;
  const FlankerTaskGame({super.key, required this.gameEngine});
  @override
  State<FlankerTaskGame> createState() => _FlankerTaskGameState();
}

class _FlankerTaskGameState extends State<FlankerTaskGame> with SingleTickerProviderStateMixin {
  FlankerDirection targetDirection = FlankerDirection.left;
  bool isCongruent = true;

  int correctTrials = 0;
  int errors = 0;
  int totalTrials = 0;
  bool gameStarted = false; // Added game state flag

  Timer? trialTimer;
  int remainingSeconds = 60;
  Stopwatch reactionStopwatch = Stopwatch();
  List<int> congruentRTs = [];
  List<int> incongruentRTs = [];

  final List<FlankerDirection> directions = FlankerDirection.values;
  final Color themeColor = Colors.pink; // Used for consistent styling

  @override
  void initState() {
    super.initState();
    // Do not call _startGame here.
  }

  @override
  void dispose() {
    trialTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 60;
      totalTrials = 0;
      correctTrials = 0;
      congruentRTs.clear();
      incongruentRTs.clear();
    });

    // 1500ms per trial
    trialTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (remainingSeconds <= 0) {
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
      _startNextTrial();
    });
    _startNextTrial(); // Initial trial start
  }

  void _startNextTrial() {
    final random = Random();
    targetDirection = directions[random.nextInt(directions.length)];
    // 60% congruent by default
    isCongruent = random.nextDouble() < 0.6;

    reactionStopwatch.reset();
    reactionStopwatch.start();
  }

  void _onResponseTap(FlankerDirection tappedDirection) {
    if (remainingSeconds <= 0 || !reactionStopwatch.isRunning) return;

    totalTrials++;
    reactionStopwatch.stop();
    int reactionTime = reactionStopwatch.elapsedMilliseconds;

    bool isCorrect = tappedDirection == targetDirection;

    // Record RT for specific trial type
    if (isCongruent) {
      congruentRTs.add(reactionTime);
    } else {
      incongruentRTs.add(reactionTime);
    }

    setState(() {
      if (isCorrect) {
        correctTrials++;
        HapticFeedback.lightImpact();
      } else {
        errors++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, reactionTime);
  }

  void _endGame() {
    trialTimer?.cancel();
    double accuracy = (totalTrials > 0 ? (correctTrials / totalTrials) : 0).clamp(0.0, 1.0) * 100;

    double avgIncongruentRT = incongruentRTs.isEmpty ? 1000.0 : incongruentRTs.reduce((a, b) => a + b) / incongruentRTs.length;

    // Score (0-5): Rewards accuracy (3 points) and speed under CONFLICT (2 points)
    double accuracyScore = (accuracy / 100) * 3.0;
    // Speed score: Higher for fast incongruent RT (Target speed 600ms)
    double speedScore = (600.0 / avgIncongruentRT).clamp(0.0, 1.0) * 2.0;

    double finalScore = (accuracyScore + speedScore).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: avgIncongruentRT, // Report conflict RT
    );
  }

  IconData _getArrowIcon(FlankerDirection direction) {
    return direction == FlankerDirection.left ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios;
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildGameScreen() {
    IconData flankerIcon = isCongruent ? _getArrowIcon(targetDirection) : _getArrowIcon(targetDirection == FlankerDirection.left ? FlankerDirection.right : FlankerDirection.left);
    IconData centerIcon = _getArrowIcon(targetDirection);

    return Scaffold(
      body: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [themeColor.withOpacity(0.05), Colors.white])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header Stat Card (Simplified)
              _buildHeaderStatCard(),
              const SizedBox(height: 40),

              // Flanker Stimulus (The central arrow is the target)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(flankerIcon, size: 50, color: Colors.grey),
                  Icon(flankerIcon, size: 50, color: Colors.grey),
                  Icon(centerIcon, size: 80, color: Colors.red), // TARGET
                  Icon(flankerIcon, size: 50, color: Colors.grey),
                  Icon(flankerIcon, size: 50, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 60),

              // Response Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildResponseButton('LEFT', Icons.arrow_back, () => _onResponseTap(FlankerDirection.left), Colors.blue),
                  const SizedBox(width: 40),
                  _buildResponseButton('RIGHT', Icons.arrow_forward, () => _onResponseTap(FlankerDirection.right), Colors.green),
                ],
              ),
              const SizedBox(height: 40),
              Text(isCongruent ? 'Congruent (Easy)' : 'Incongruent (INHIBIT)', style: TextStyle(fontSize: 16, color: isCongruent ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Flanker Task',
      description: 'Your goal is to quickly identify the direction of the **central arrow** while ignoring the distracting arrows (flankers) on either side.',
      rules: [
        RuleItem('👁️', 'Focus', 'Only the direction of the central arrow matters. The flankers will often point the opposite way.'),
        RuleItem('🧠', 'Conflict', 'When flankers point the opposite way (incongruent trial), you must use selective attention and inhibition to ignore them.'),
        RuleItem('⏱️', 'Speed', 'Respond as quickly and accurately as possible by tapping the LEFT or RIGHT button.'),
      ],
      onStart: _startGame,
      icon: Icons.compare_arrows_outlined,
      gradientColors: [Colors.pink, Colors.red],
      themeColor: themeColor,
    );
  }

  Widget _buildResponseButton(String label, IconData icon, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeaderStatCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Time', '${remainingSeconds}s', remainingSeconds > 10 ? themeColor : Colors.red),
          _buildStat('Correct', '$correctTrials', Colors.green),
          _buildStat('Total', '$totalTrials', Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
// 22. SUSTAINED VIGILANCE GAME (Sustained Attention, Low-Frequency Targets)
class SustainedVigilanceGame extends StatefulWidget {
  final GameEngine gameEngine;
  const SustainedVigilanceGame({super.key, required this.gameEngine});
  @override
  State<SustainedVigilanceGame> createState() => _SustainedVigilanceGameState();
}

class _SustainedVigilanceGameState extends State<SustainedVigilanceGame> {
  final Color themeColor = Colors.teal;

  String currentEvent = 'Bus is driving...';
  bool isTarget = false; // Is the CURRENT event a target?
  bool _previousIsTarget = false; // Was the LAST event a target?
  bool _responseMadeInInterval = false; // Has the user responded since the event started?

  int totalEvents = 0;
  int hits = 0; // Correct tap on target
  int misses = 0; // Failure to tap on target
  int falseAlarms = 0; // Tap on non-target

  Timer? eventTimer;
  int remainingSeconds = 120;
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    // Do not call _startGame here. Let the build method show rules first.
  }

  @override
  void dispose() {
    eventTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 120;
      totalEvents = 0;
      hits = 0;
      misses = 0;
      falseAlarms = 0;
      _previousIsTarget = false;
      _responseMadeInInterval = false;
    });

    // Start trial sequence immediately
    _runEvent();

    // Start main time countdown
    eventTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (remainingSeconds <= 0) {
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
      _runEvent();
    });
  }

  void _runEvent() {
    final random = Random();

    // 1. Check for Misses from the PREVIOUS interval
    if (_previousIsTarget && !_responseMadeInInterval) {
      setState(() => misses++);
      HapticFeedback.heavyImpact(); // Missed target feedback
    }

    // 2. Prepare for the next event
    totalEvents++;

    // Check for target (10% target probability)
    isTarget = random.nextDouble() < 0.1;

    setState(() {
      _previousIsTarget = isTarget; // Store for miss check in the *next* trial
      _responseMadeInInterval = false;
      currentEvent = isTarget ? 'Passenger with suitcase boards!' : 'Bus is driving normally...';
    });

    // Record non-response (RT = 2000ms) for the previous trial if it was non-target.
    // If it was a target, the trial is recorded in _onScreenTap.
  }

  void _onScreenTap() {
    if (remainingSeconds <= 0 || _responseMadeInInterval) return;

    setState(() {
      _responseMadeInInterval = true;
    });

    // Determine scoring based on the current visible event (isTarget)
    if (isTarget) {
      // Correct Tap (Hit)
      setState(() => hits++);
      HapticFeedback.lightImpact();
      widget.gameEngine.recordTrial(true, 500); // Record Hit RT
    } else {
      // Incorrect Tap (False Alarm)
      setState(() => falseAlarms++);
      HapticFeedback.heavyImpact();
      widget.gameEngine.recordTrial(false, 500); // Record False Alarm RT
    }

    // Reset the target status for the UI immediately after tap
    setState(() {
      isTarget = false;
      currentEvent = 'Response Recorded. Monitoring...';
    });
  }

  void _endGame() {
    eventTimer?.cancel();

    // Final check for a miss in the very last interval if it was a target
    if (_previousIsTarget && !_responseMadeInInterval) {
      misses++;
    }

    int totalTargets = hits + misses;
    double accuracy = totalTargets > 0 ? (hits / totalTargets).clamp(0.0, 1.0) * 100 : 0;

    // Score (0-5): Focus on Vigilance (Misses) and Inhibition (False Alarms)

    // Vigilance Score: Rewards hits / total targets (Max 3.0)
    double vigilanceScore = (accuracy / 100) * 3.0;

    // Inhibition Penalty: Penalize 2.0 points maximum based on False Alarms/Total Non-targets
    int totalNonTargets = totalEvents - totalTargets;
    double falseAlarmRate = totalNonTargets > 0 ? (falseAlarms / totalNonTargets) : 0;
    double inhibitionPenalty = falseAlarmRate.clamp(0.0, 1.0) * 2.0;

    double finalScore = (vigilanceScore - inhibitionPenalty).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: 2000, // Average interval
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildGameScreen() {
    // Determine button appearance
    Color buttonColor = isTarget && !_responseMadeInInterval ? Colors.red.shade400 : Colors.amber;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [themeColor.withOpacity(0.05), Colors.white])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Time Remaining: ${remainingSeconds}s', style: const TextStyle(fontSize: 20, color: Colors.teal)),
              const SizedBox(height: 40),

              Text(currentEvent, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 60),

              // Tap button acts as main response area
              ElevatedButton(
                onPressed: _onScreenTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  minimumSize: const Size(250, 90),
                ),
                child: Text(
                    isTarget && !_responseMadeInInterval ? 'TARGET! TAP NOW!' : 'Monitor Events',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isTarget ? Colors.white : Colors.black87)
                ),
              ),
              const SizedBox(height: 40),

              Text('Hits: $hits | Misses: $misses | False Alarms: $falseAlarms', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              Text('Total Events: $totalEvents', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Sustained Vigilance Test',
      description: 'Monitor the stream of events for a rare target event ("Passenger with suitcase boards!"). This is a long, monotonous test designed to measure your attention span.',
      rules: [
        RuleItem('⏰', 'Duration', 'The test runs for 120 seconds. Low target frequency makes attention difficult.'),
        RuleItem('👆', 'Action', 'Tap the screen (or the button) **only** when you see the rare target event.'),
        RuleItem('❌', 'Penalty', 'Both missing a target (**Miss**) and tapping when there is no target (**False Alarm**) severely hurt your score.'),
      ],
      onStart: _startGame,
      icon: Icons.access_time_outlined,
      gradientColors: [Colors.teal, Colors.cyan],
      themeColor: themeColor,
    );
  }
}
// 23. VISUAL CANCELLATION GAME (Scanning, Selective Attention)
class VisualCancellationGame extends StatefulWidget {
  final GameEngine gameEngine;
  const VisualCancellationGame({super.key, required this.gameEngine});
  @override
  State<VisualCancellationGame> createState() => _VisualCancellationGameState();
}

class _VisualCancellationGameState extends State<VisualCancellationGame> {
  final Color themeColor = Colors.amber;
  final int matrixSize = 8;
  final String target = 'A';
  final List<String> distractors = ['B', 'E', 'F', 'H', 'K', 'L', 'M', 'N', 'R', 'T'];

  List<String> matrix = [];
  List<bool> marked = [];

  int totalTargets = 0;
  int targetsFound = 0;
  int falseMarks = 0;
  bool gameStarted = false; // Add game state flag

  Timer? gameTimer;
  int remainingSeconds = 60;
  Stopwatch timer = Stopwatch();

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here. Let the build method handle the rules screen.
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    timer.stop();
    super.dispose();
  }

  void _generateMatrix() {
    final random = Random();
    int size = matrixSize * matrixSize;
    totalTargets = 0; // Reset target count for matrix generation

    matrix = List.generate(size, (index) {
      if (random.nextDouble() < 0.2) { // 20% chance of target
        totalTargets++;
        return target;
      }
      return distractors[random.nextInt(distractors.length)];
    });
    marked = List.generate(size, (_) => false);
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 60;
      targetsFound = 0;
      falseMarks = 0;
      _generateMatrix(); // Generate fresh matrix for the new game
      timer.reset();
      timer.start();
    });

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (remainingSeconds <= 0) {
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  void _onCellTap(int index) {
    if (remainingSeconds <= 0 || marked[index]) return;

    setState(() {
      if (matrix[index] == target) {
        targetsFound++;
        HapticFeedback.lightImpact();
      } else {
        falseMarks++;
        HapticFeedback.heavyImpact();
      }
      marked[index] = true;

      // OPTIONAL: End game early if all targets are found
      if (targetsFound >= totalTargets) {
        _endGame();
      }
    });
  }

  void _endGame() {
    gameTimer?.cancel();
    timer.stop();

    double targetsChecked = (targetsFound + falseMarks) as double;

    // Accuracy is based on Hit Rate (targets found / total targets)
    double accuracy = (totalTargets > 0 ? (targetsFound / totalTargets) : 0).clamp(0.0, 1.0) * 100;

    // Score (0-5): Based on accuracy (3.5 points) and penalized by false marks (1.5 points max)
    double accuracyScore = (accuracy / 100) * 3.5;

    // Penalty is based on False Mark Rate (False Marks / Total Taps made)
    double falseMarkRate = (targetsChecked > 0 ? (falseMarks / targetsChecked) : 0);

    // Penalize higher for tapping wrong cells frequently
    double inhibitionPenalty = falseMarkRate.clamp(0.0, 1.0) * 1.5;

    double finalScore = (accuracyScore - inhibitionPenalty).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: timer.elapsedMilliseconds.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildGameScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [themeColor.withOpacity(0.05), Colors.white])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Find and tap all the "$target" characters.', style: const TextStyle(fontSize: 20, color: Colors.black87)),
              const SizedBox(height: 10),
              // Header Stat Card
              _buildHeaderStatCard(),
              const SizedBox(height: 20),

              SizedBox(
                width: matrixSize * 40.0, height: matrixSize * 40.0,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: matrixSize),
                  itemCount: matrixSize * matrixSize,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _onCellTap(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: marked[index] ? (matrix[index] == target ? Colors.green.shade100 : Colors.red.shade100) : Colors.white,
                          border: Border.all(color: Colors.grey.shade300, width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            matrix[index],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: marked[index] ? (matrix[index] == target ? Colors.green.shade800 : Colors.red.shade800) : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              Text('Time Remaining: ${remainingSeconds}s', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Visual Cancellation Test',
      description: 'Test your ability to scan a visual field and selectively attend to targets amidst a dense field of distractors.',
      rules: [
        RuleItem('🔎', 'Target', 'Your target is the letter "$target". You must find and tap every instance of it.'),
        RuleItem('👆', 'Action', 'Tap the squares containing the target letter as quickly as possible.'),
        RuleItem('❌', 'Penalty', 'Tapping a square that is NOT the target (a Distractor) results in a False Mark and will penalize your score.'),
      ],
      onStart: _startGame,
      icon: Icons.cancel_schedule_send_outlined,
      gradientColors: [themeColor, Colors.orange],
      themeColor: themeColor,
    );
  }

  Widget _buildHeaderStatCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Targets', '$totalTargets', Colors.blueGrey),
          _buildStat('Found', '$targetsFound', Colors.green),
          _buildStat('Errors', '$falseMarks', Colors.red),
          _buildStat('Time', '${remainingSeconds}s', remainingSeconds > 10 ? themeColor : Colors.red),
        ],
      ),
    );
  }

  // NOTE: Assuming _buildStat is defined locally or available globally
  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}

// 24. DICHOTIC LISTENING GAME (Auditory Selective Attention)
class DichoticListeningGame extends StatefulWidget {
  final GameEngine gameEngine;
  const DichoticListeningGame({super.key, required this.gameEngine});
  @override
  State<DichoticListeningGame> createState() => _DichoticListeningGameState();
}

class _DichoticListeningGameState extends State<DichoticListeningGame> {
  final Color themeColor = Colors.blueGrey;
  final List<String> letters = ['A', 'B', 'C', 'D', 'E'];
  String leftCue = '';
  String rightCue = '';
  final String targetEar = 'RIGHT'; // The required focus ear

  List<String> rightSequence = [];
  List<String> userRecall = [];
  final int sequenceLength = 6; // Increased length for a meaningful test

  bool playing = false; // Set to false initially, true during cue display
  bool recalling = false; // Tracks if the game is in the input phase
  int currentStep = 0;
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here.
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      recalling = false;
      currentStep = 0;
      userRecall.clear();
      _generateSequences();
    });
    _playNextStep();
  }

  void _generateSequences() {
    final random = Random();
    // Generate the target sequence (the sequence the user must recall)
    rightSequence = List.generate(sequenceLength, (_) => letters[random.nextInt(letters.length)]);
  }

  void _playNextStep() async {
    if (currentStep < rightSequence.length) {
      final random = Random();
      // Generate a distractor that is NOT the target letter for the current step
      String distractor;
      do { distractor = letters[random.nextInt(letters.length)]; } while (distractor == rightSequence[currentStep]);

      // FIX: Ensure the target sequence always lands in the RIGHT cue.
      // The LEFT cue gets a random distractor or the target, confusing the user.

      String distractorForLeft = letters[random.nextInt(letters.length)];

      setState(() {
        leftCue = distractorForLeft;
        rightCue = rightSequence[currentStep]; // Target is always visible in the right ear cue
        playing = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      setState(() {
        leftCue = '';
        rightCue = '';
        playing = false;
        currentStep++;
      });
      await Future.delayed(const Duration(milliseconds: 500)); // Inter-stimulus interval
      _playNextStep();
    } else {
      // Start recall phase
      setState(() {
        recalling = true;
      });
    }
  }

  void _submitRecall(String letter) {
    if (!recalling) return;

    setState(() {
      userRecall.add(letter);
    });

    if (userRecall.length == rightSequence.length) {
      _checkRecall();
    }
  }

  void _checkRecall() {
    int score = 0;
    for (int i = 0; i < rightSequence.length; i++) {
      if (i < userRecall.length && userRecall[i] == rightSequence[i]) {
        score++;
      }
    }

    double accuracy = (score / rightSequence.length) * 100;
    double finalScore = (accuracy / 100) * 5.0;

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: 500,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildGameScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [themeColor.withOpacity(0.05), Colors.white])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Focus only on the $targetEar ear sequence.', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCueDisplay('LEFT Ear', leftCue, Colors.red),
                  _buildCueDisplay('RIGHT Ear', rightCue, Colors.green),
                ],
              ),

              const SizedBox(height: 50),

              Text(recalling ? 'Enter the sequence:' : 'Listening to Step ${currentStep + 1}', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),

              if (recalling)
                Wrap(
                  spacing: 10,
                  children: letters.map((letter) => ElevatedButton(onPressed: () => _submitRecall(letter), child: Text(letter))).toList(),
                ),

              const SizedBox(height: 20),
              Text('Recalled: ${userRecall.join(', ')}', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCueDisplay(String ear, String cue, Color color) {
    return Container(
      width: 150, height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(ear, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(cue, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Dichotic Listening Test',
      description: 'Tests your Auditory Selective Attention by requiring you to focus on the target ear sequence while ignoring the distracting sequence in the opposite ear.',
      rules: [
        RuleItem('👂', 'Target Ear', 'You must focus ONLY on the sequence presented to the **RIGHT** ear. The LEFT ear provides distractor stimuli.'),
        RuleItem('🧠', 'Recall', 'After the sequence ends, recall the letters heard in the RIGHT ear, in the correct order.'),
        RuleItem('🚫', 'Distractors', 'Ignore the letters presented to the LEFT ear.'),
      ],
      onStart: _startGame,
      icon: Icons.headphones_outlined,
      gradientColors: [Colors.blueGrey.shade600, Colors.grey.shade800],
      themeColor: Colors.brown.shade600,
    );
  }
}

// 25. RAPID STIMULUS DETECTION GAME (Simple Visual Attention)
// 25. RAPID STIMULUS DETECTION GAME (Simple Visual Attention)
class RapidStimulusDetectionGame extends StatefulWidget {
  final GameEngine gameEngine;
  const RapidStimulusDetectionGame({super.key, required this.gameEngine});
  @override
  State<RapidStimulusDetectionGame> createState() => _RapidStimulusDetectionGameState();
}

class _RapidStimulusDetectionGameState extends State<RapidStimulusDetectionGame> {
  final Color themeColor = Colors.lightBlue;
  bool stimulusActive = false;
  bool gameStarted = false; // Added game state flag

  int totalTrials = 0;
  int correctResponses = 0;

  Timer? flashTimer;
  Timer? intervalTimer;
  int remainingSeconds = 60;
  Stopwatch reactionStopwatch = Stopwatch();
  List<int> reactionTimes = [];

  // Stats used for display, initialized below
  double avgRT = 0.0;

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here. Let the build method show rules first.
  }

  @override
  void dispose() {
    flashTimer?.cancel();
    intervalTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 60;
      totalTrials = 0;
      correctResponses = 0;
      reactionTimes.clear();
      avgRT = 0.0;
    });

    _startFlashSequence();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (remainingSeconds <= 0) {
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  void _startFlashSequence() {
    if (remainingSeconds <= 0) return;

    final random = Random();
    int delay = 500 + random.nextInt(1000); // Random delay between 500ms and 1500ms

    intervalTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || remainingSeconds <= 0) return;

      setState(() => stimulusActive = true);
      reactionStopwatch.reset();
      reactionStopwatch.start();

      flashTimer = Timer(const Duration(milliseconds: 200), () {
        if (!mounted || remainingSeconds <= 0) return;

        // Miss logic is now implicit: if stimulusActive is true here, they missed it.
        setState(() => stimulusActive = false);
        _startFlashSequence();
      });
    });
  }

  void _onScreenTap() {
    if (!stimulusActive) {
      // False alarm is not explicitly counted here but results in a wasted tap/no score.
      HapticFeedback.heavyImpact();
      return;
    }
    if (!reactionStopwatch.isRunning) return;

    reactionStopwatch.stop();
    int reactionTime = reactionStopwatch.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    setState(() {
      correctResponses++;
      totalTrials++; // Total taps, excluding taps when not active
      stimulusActive = false;
      // Recalculate avgRT for display update
      avgRT = reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;
    });

    HapticFeedback.lightImpact();
    widget.gameEngine.recordTrial(true, reactionTime);

    flashTimer?.cancel();
    intervalTimer?.cancel();
    _startFlashSequence();
  }

  void _endGame() {
    flashTimer?.cancel();
    intervalTimer?.cancel();

    double finalAvgRT = reactionTimes.isEmpty ? 1000.0 : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;
    // Accuracy is complex here (taps on target / total targets shown). Since we don't
    // track total targets shown without tracking misses, we approximate:
    double accuracy = (correctResponses / totalTrials).clamp(0.0, 1.0) * 100; // Based on successful taps / all taps

    // Score (0-5): Focused on low average RT (speed)
    double targetRT = 300.0; // Set aggressive RT target for 5 points
    double speedScore = (targetRT / finalAvgRT).clamp(0.0, 1.0) * 5.0;

    widget.gameEngine.completeGame(
      score: speedScore,
      accuracy: accuracy,
      reactionTime: finalAvgRT,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Rapid Stimulus Detection',
      description: 'Test your raw visual detection speed (Simple Reaction Time).',
      rules: [
        RuleItem('💡', 'Target', 'Watch the grey circle. It will turn YELLOW briefly.'),
        RuleItem('👆', 'Action', 'Tap the screen or the button as quickly as possible the instant it turns yellow.'),
        RuleItem('⏱️', 'Scoring', 'Your score is based purely on your average reaction speed.'),
      ],
      onStart: _startGame,
      icon: Icons.flash_on_outlined,
      gradientColors: [Colors.brown.shade600, Colors.blue.shade900],
      themeColor: Colors.brown.shade600,
    );
  }

  Widget _buildGameScreen() {
    return GestureDetector(
      onTap: _onScreenTap,
      child: Scaffold(
        appBar: AppBar(title: const Text('Rapid Stimulus Detection'), backgroundColor: Colors.brown.shade600),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Time Remaining: ${remainingSeconds}s', style: const TextStyle(fontSize: 20, color: Colors.lightBlue)),
              const SizedBox(height: 60),

              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  color: stimulusActive ? Colors.yellow : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  boxShadow: stimulusActive ? [BoxShadow(color: Colors.yellow, blurRadius: 30)] : null,
                ),
                child: Center(
                  child: Text(stimulusActive ? 'TAP!' : 'Wait...', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: stimulusActive ? Colors.black : Colors.grey.shade600)),
                ),
              ),
              const SizedBox(height: 60),
              Text('Avg RT: ${avgRT.toStringAsFixed(0)}ms | Total Taps: $correctResponses', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              Text('False Taps Ignored: ${totalTrials - correctResponses}', style: TextStyle(fontSize: 16, color: Colors.red.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}
// 26-30: Processing Speed
// File: game_implementations_ps_ar

// NOTE: GameEngine, GameLevel, GameState, etc., must be imported or available globally.

// --------------------------------------------------------------------------
// HELPER ENUMS AND DATA MODELS (PS & AR Games)
// --------------------------------------------------------------------------

enum ShapeType { square, triangle, circle }
enum PatternRule { addition, subtraction, alternation }
enum SyllogismValidity { valid, invalid }

// --- Pattern Class (Assumed Global Definition) ---

class Pattern {
  final List<ShapeType> shapes;
  final List<double> sizes;
  final List<Color> colors; // <-- THIS MUST BE PRESENT

  // The constructor must accept all three lists
  Pattern(this.shapes, this.sizes, this.colors);

  // The equals method must compare all three lists for logic games
  bool equals(Pattern other) {
    if (shapes.length != other.shapes.length ||
        sizes.length != other.sizes.length ||
        colors.length != other.colors.length) {
      return false;
    }

    // Check shapes
    for (int i = 0; i < shapes.length; i++) {
      if (shapes[i] != other.shapes[i]) return false;
    }
    // Check sizes
    for (int i = 0; i < sizes.length; i++) {
      if (sizes[i] != other.sizes[i]) return false;
    }
    // Check colors
    for (int i = 0; i < colors.length; i++) {
      if (colors[i] != other.colors[i]) return false;
    }
    return true;
  }
}

// --------------------------------------------------------------------------
// PROCESSING SPEED GAMES (IDs 26-30)
// --------------------------------------------------------------------------
// 26. PATTERN MATCHING BLITZ (Visual Scanning, Choice RT)
class PatternMatchingBlitzGame extends StatefulWidget {
  final GameEngine gameEngine;
  const PatternMatchingBlitzGame({super.key, required this.gameEngine});
  @override
  State<PatternMatchingBlitzGame> createState() => _PatternMatchingBlitzGameState();
}

class _PatternMatchingBlitzGameState extends State<PatternMatchingBlitzGame> {
  final Color themeColor = Colors.orange;
  Pattern? patternA;
  Pattern? patternB;
  bool areSame = false;
  bool gameStarted = false; // Added game state flag

  int correctResponses = 0;
  int incorrectResponses = 0;
  int totalTrials = 0;
  List<int> reactionTimes = [];

  Timer? trialTimer;
  int remainingSeconds = 60;
  Stopwatch reactionStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here.
  }

  @override
  void dispose() {
    trialTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 60;
      totalTrials = 0;
      correctResponses = 0;
      incorrectResponses = 0;
      reactionTimes.clear();
    });

    _startNextTrial();
    trialTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (remainingSeconds <= 0) {
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  void _generatePatterns() {
    final random = Random();
    int length = 4;
    patternA = Pattern(
        List.generate(length, (_) => ShapeType.values[random.nextInt(3)]), // Argument 1: Shapes (The actual data)
        [1.0],                                                                // Argument 2: Sizes (Placeholder list)
        [Colors.black]                                                        // Argument 3: Colors (Placeholder list)
    );

    areSame = random.nextBool();

    if (areSame) {
      // Ensure patternB is created explicitly as a new list of the same objects for clean UI updates
      patternB = Pattern(
          List.from(patternA!.shapes), // Argument 1: Shapes (The actual data)
          List.from(patternA!.sizes),  // Argument 2: Sizes (Placeholder list)
          List.from(patternA!.colors) // Argument 3: Colors (Placeholder list)
      );
    } else {
      List<ShapeType> shapesB = List.from(patternA!.shapes);
      int diffIndex = random.nextInt(length);
      // Ensure the different shape is actually different
      ShapeType original = shapesB[diffIndex];
      ShapeType newShape;
      do {
        newShape = ShapeType.values[random.nextInt(3)];
      } while (newShape == original);
      shapesB[diffIndex] = newShape;
      patternB = Pattern(shapesB, [1.0], [Colors.black]);
    }
  }

  void _startNextTrial() {
    _generatePatterns();
    reactionStopwatch.reset();
    reactionStopwatch.start();
  }

  void _onResponseTap(bool match) {
    if (remainingSeconds <= 0 || !reactionStopwatch.isRunning) return;

    reactionStopwatch.stop();
    int reactionTime = reactionStopwatch.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    totalTrials++;
    bool isCorrect = (match == areSame);

    setState(() {
      if (isCorrect) {
        correctResponses++;
        HapticFeedback.lightImpact();
      } else {
        incorrectResponses++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, reactionTime);
    _startNextTrial();
  }

  void _endGame() {
    trialTimer?.cancel();
    double accuracy = (totalTrials > 0 ? (correctResponses / totalTrials) : 0).clamp(0.0, 1.0) * 100;
    double avgRT = reactionTimes.isEmpty ? 1000.0 : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // Score (0-5): Rewards fast throughput and high accuracy.
    double throughputFactor = (totalTrials / 30.0).clamp(0.0, 1.0); // Max 1.0 for 30 trials
    double accuracyFactor = (accuracy / 100);

    // Weight speed and accuracy equally (Max 5.0)
    double finalScore = (throughputFactor * accuracyFactor) * 5.0;

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: avgRT,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Pattern Matching Blitz',
      description: 'Quickly compare two complex visual patterns and decide if they are exactly the SAME or DIFFERENT.',
      rules: [
        RuleItem('👁️', 'Comparison', 'Compare the four shapes in Pattern A with the four shapes in Pattern B.'),
        RuleItem('👆', 'Action', 'Tap "SAME" if all four shapes match in position and type. Tap "DIFFERENT" otherwise.'),
        RuleItem('⏱️', 'Scoring', 'Score rewards high throughput (many correct answers per minute) and high accuracy.'),
      ],
      onStart: _startGame,
      icon: Icons.compare_outlined,
      gradientColors: [themeColor, Colors.deepOrange],
      themeColor: themeColor,
    );
  }

  Widget _buildShapeWidget(ShapeType type, Color color) {
    IconData icon = type == ShapeType.square ? Icons.square : (type == ShapeType.triangle ? Icons.change_history : Icons.circle);
    return Icon(icon, size: 40, color: color);
  }

  Widget _buildPatternDisplay(Pattern? pattern) {
    if (pattern == null) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pattern.shapes.map((shape) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: _buildShapeWidget(shape, Colors.blueGrey),
      )).toList(),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Time: ${remainingSeconds}s | Correct: $correctResponses', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
            const SizedBox(height: 50),

            // Pattern A
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.teal.shade200)),
              child: _buildPatternDisplay(patternA),
            ),
            const SizedBox(height: 10),
            const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Pattern B
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.teal.shade200)),
              child: _buildPatternDisplay(patternB),
            ),

            const SizedBox(height: 50),

            // Response Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResponseButton('SAME', true, Colors.green),
                const SizedBox(width: 40),
                _buildResponseButton('DIFFERENT', false, Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            Text('Errors: $incorrectResponses', style: TextStyle(fontSize: 16, color: Colors.red.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseButton(String label, bool value, Color color) {
    return ElevatedButton(
      onPressed: () => _onResponseTap(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 20, color: Colors.white)),
    );
  }
}
// 27. COLOR/SHAPE SEARCH GAME (Feature Search Speed)
class ColorShapeSearchGame extends StatefulWidget {
  final GameEngine gameEngine;
  const ColorShapeSearchGame({super.key, required this.gameEngine});
  @override
  State<ColorShapeSearchGame> createState() => _ColorShapeSearchGameState();
}
// --- Tuple Helper Class Definition ---
class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  // Constructor
  Tuple(this.item1, this.item2);

  // Optional: Add equals/hashCode if you plan to use Tuples in Maps or Sets
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Tuple<T1, T2> &&
              runtimeType == other.runtimeType &&
              item1 == other.item1 &&
              item2 == other.item2;

  @override
  int get hashCode => item1.hashCode ^ item2.hashCode;
}
class _ColorShapeSearchGameState extends State<ColorShapeSearchGame> {
  final Color themeColor = Colors.green;
  final List<Color> colors = [Colors.red, Colors.blue, Colors.green];
  final List<IconData> shapes = [Icons.star, Icons.circle, Icons.square];

  Color targetColor = Colors.red;
  // IconData targetShape = Icons.star; // Not used in Feature Search

  List<Tuple<Color, IconData>> gridItems = [];
  List<bool> isMarked = []; // Tracks if a cell has been tapped

  int correctResponses = 0;
  int falseAlarms = 0;
  int targetsRemaining = 0;
  int targetsGenerated = 0; // Tracks total targets shown across trials
  bool gameStarted = false;

  Timer? gameTimer;
  int remainingSeconds = 45;
  Stopwatch reactionStopwatch = Stopwatch();

  // NOTE: Assuming Tuple<T1, T2> is globally accessible.

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here.
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _generateGrid() {
    final random = Random();
    targetColor = colors[random.nextInt(colors.length)];

    targetsRemaining = 0;
    gridItems = List.generate(25, (index) {
      Color color = colors[random.nextInt(colors.length)];
      IconData shape = shapes[random.nextInt(shapes.length)];

      // 25% chance of being a target
      if (random.nextDouble() < 0.25) {
        color = targetColor; // Target feature is only the COLOR
        // Shape is random, increasing the distraction load
        targetsRemaining++;
        targetsGenerated++;
      }
      return Tuple(color, shape);
    });
    isMarked = List.generate(25, (_) => false);
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 45;
      correctResponses = 0;
      falseAlarms = 0;
      targetsGenerated = 0;
    });

    _generateGrid(); // Generate initial grid
    reactionStopwatch.start();

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (remainingSeconds <= 0) {
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  void _onItemTap(int index) {
    if (remainingSeconds <= 0 || isMarked[index]) return;

    // Critical: Stop timer only on the first tap of the round to record RT for that tap
    if (!reactionStopwatch.isRunning) reactionStopwatch.start();

    Tuple<Color, IconData> item = gridItems[index];
    bool isTarget = item.item1 == targetColor;

    setState(() {
      isMarked[index] = true; // Mark as processed

      if (isTarget) {
        correctResponses++;
        targetsRemaining--;
        HapticFeedback.lightImpact();
      } else {
        falseAlarms++;
        HapticFeedback.heavyImpact();
      }
    });

    // Record this tap as a trial for engine
    widget.gameEngine.recordTrial(isTarget, reactionStopwatch.elapsedMilliseconds);

    if (targetsRemaining <= 0) {
      _generateGrid(); // New trial
    }
  }

  void _endGame() {
    gameTimer?.cancel();
    reactionStopwatch.stop();

    // Accuracy is measured by how many of the generated targets were successfully found (Hit Rate).
    num hitRate = (targetsGenerated > 0 ? (correctResponses / targetsGenerated) : 0).clamp(0.0, 1.0);
    double accuracy = hitRate * 100;

    // Throughput (Total correct responses per minute)
    double throughput = correctResponses / (45.0 / 60.0); // Correct responses per 45 seconds -> per minute

    // Score (0-5): Rewards high Hit Rate (3 points) and high Throughput (2 points max) with a penalty for FAs.

    // Hit Score: Max 3.0
    double hitScore = hitRate * 3.0;

    // Throughput Score: Max 2.0 (Target throughput: 20 per minute)
    double throughputScore = (throughput / 20.0).clamp(0.0, 1.0) * 2.0;

    // Penalty: Penalize 0.5 points per False Alarm (Max 5.0 total penalty)
    double finalScore = (hitScore + throughputScore - (falseAlarms * 0.5)).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: reactionStopwatch.elapsedMilliseconds.toDouble() / (correctResponses + falseAlarms).clamp(1, double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Color/Shape Search',
      description: 'Rapidly scan the grid and tap ONLY the items that match the target feature (the target color).',
      rules: [
        RuleItem('🎯', 'Target Feature', 'The target is defined by its **COLOR** (e.g., Red). The shape of the object is irrelevant and acts as a distractor.'),
        RuleItem('👆', 'Action', 'Tap all items matching the target color as quickly as possible. Every tap counts towards your throughput.'),
        RuleItem('⏱️', 'Scoring', 'Score rewards high speed and hit rate (finding targets) while heavily penalizing False Alarms.'),
      ],
      onStart: _startGame,
      icon: Icons.color_lens_outlined,
      gradientColors: [themeColor, Colors.lightGreen],
      themeColor: themeColor,
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Color/Shape Search'), backgroundColor: themeColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Time: ${remainingSeconds}s | Found: $correctResponses | Errors: $falseAlarms', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
            const SizedBox(height: 20),

            // Target Indicator (Focus is only on color)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: targetColor, width: 2)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: targetColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Find ONLY the ${targetColor == Colors.red ? "RED" : targetColor == Colors.blue ? "BLUE" : "GREEN"} items.', style: TextStyle(color: targetColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Search Grid
            SizedBox(
              width: 5 * 60.0, height: 5 * 60.0,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                itemCount: 25,
                itemBuilder: (context, index) {
                  Tuple<Color, IconData> item = gridItems[index];
                  bool marked = isMarked[index];

                  return GestureDetector(
                    onTap: () => _onItemTap(index),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: marked ? (item.item1 == targetColor ? Colors.green.shade100 : Colors.red.shade100) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Icon(item.item2, size: 30, color: item.item1)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 28. LETTER/NUMBER TRANSPOSITION GAME (Dual-Type Encoding Speed)
class LetterNumberTranspositionGame extends StatefulWidget {
  final GameEngine gameEngine;
  const LetterNumberTranspositionGame({super.key, required this.gameEngine});
  @override
  State<LetterNumberTranspositionGame> createState() => _LetterNumberTranspositionGameState();
}

class _LetterNumberTranspositionGameState extends State<LetterNumberTranspositionGame> {
  final Color themeColor = Colors.purple;
  String currentStimulus = '';
  bool isLetter = false;
  bool gameStarted = false; // Added game state flag

  int correctResponses = 0;
  int incorrectResponses = 0;
  int totalTrials = 0;
  List<int> reactionTimes = [];

  Timer? trialTimer;
  int remainingSeconds = 60;
  Stopwatch reactionStopwatch = Stopwatch();

  final List<String> letters = ['A', 'B', 'C', 'D', 'E'];
  final List<String> numbers = ['1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here.
  }

  @override
  void dispose() {
    trialTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 60;
      totalTrials = 0;
      correctResponses = 0;
      incorrectResponses = 0;
      reactionTimes.clear();
    });

    _startNextTrial();
    trialTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (remainingSeconds <= 0) {
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  void _startNextTrial() {
    final random = Random();
    isLetter = random.nextBool();

    currentStimulus = isLetter ? letters[random.nextInt(letters.length)] : numbers[random.nextInt(numbers.length)];

    reactionStopwatch.reset();
    reactionStopwatch.start();
  }

  void _onResponseTap(bool tappedLetter) {
    if (remainingSeconds <= 0 || !reactionStopwatch.isRunning) return;

    reactionStopwatch.stop();
    int reactionTime = reactionStopwatch.elapsedMilliseconds;
    reactionTimes.add(reactionTime);

    totalTrials++;
    bool isCorrect = (tappedLetter == isLetter);

    setState(() {
      if (isCorrect) {
        correctResponses++;
        HapticFeedback.lightImpact();
      } else {
        incorrectResponses++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, reactionTime);
    _startNextTrial();
  }

  void _endGame() {
    trialTimer?.cancel();
    double accuracy = (totalTrials > 0 ? (correctResponses / totalTrials) : 0).clamp(0.0, 1.0) * 100;
    double avgRT = reactionTimes.isEmpty ? 1000.0 : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;

    // FIX: Score based on Throughput and RT normalization (Max 5.0)
    // Target Throughput: 40 trials in 60s (1.5s per trial)
    double throughputFactor = (totalTrials / 40.0).clamp(0.0, 1.0) * 2.5;

    // Accuracy Factor: Max 2.5
    double accuracyFactor = (accuracy / 100) * 2.5;

    double finalScore = (throughputFactor + accuracyFactor).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: avgRT,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Letter/Number Transposition',
      description: 'Quickly categorize the presented stimulus as either a Letter or a Number. Measures encoding and decision speed across categories.',
      rules: [
        RuleItem('👁️', 'Stimulus', 'A single character (A-E or 1-5) will appear.'),
        RuleItem('👆', 'Action', 'Tap the corresponding category button (LETTER or NUMBER) as fast and accurately as possible.'),
        RuleItem('⏱️', 'Scoring', 'Score rewards high throughput (trials completed per minute) adjusted by accuracy.'),
      ],
      onStart: _startGame,
      icon: Icons.sort_by_alpha,
      gradientColors: [themeColor, Colors.deepPurple],
      themeColor: themeColor,
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Letter/Number Transposition'), backgroundColor: themeColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Time: ${remainingSeconds}s | Correct: $correctResponses | Wrong: $incorrectResponses', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
            const SizedBox(height: 50),

            // Stimulus
            Container(
              width: 150, height: 150,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purple, width: 3)),
              child: Center(child: Text(currentStimulus, style: TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: Colors.purple))),
            ),

            const SizedBox(height: 50),

            // Response Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResponseButton('LETTER', true, Colors.deepPurple),
                const SizedBox(width: 40),
                _buildResponseButton('NUMBER', false, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseButton(String label, bool value, Color color) {
    return ElevatedButton(
      onPressed: () => _onResponseTap(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 20, color: Colors.white)),
    );
  }
}

// 29. FINGER TAPPING RATE GAME (Motor Speed, Motor Dexterity)
class FingerTappingRateGame extends StatefulWidget {
  final GameEngine gameEngine;
  const FingerTappingRateGame({super.key, required this.gameEngine});
  @override
  State<FingerTappingRateGame> createState() => _FingerTappingRateGameState();
}

class _FingerTappingRateGameState extends State<FingerTappingRateGame> {
  final Color themeColor = Colors.cyan;
  int taps = 0;
  bool isTapping = false;
  bool gameStarted = false; // Added game state flag
  Timer? gameTimer;
  int remainingSeconds = 10;
  final int totalDuration = 10; // Total duration in seconds

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _startInitial() {
    // Set initial state without starting timer
    setState(() {
      gameStarted = false;
      taps = 0;
      remainingSeconds = totalDuration;
      isTapping = false;
    });
  }

  // FIX: _startGame now properly handles initialization and timer start
  void _startGame() {
    setState(() {
      gameStarted = true;
      taps = 0;
      remainingSeconds = totalDuration;
      isTapping = true;
    });

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }

      if (remainingSeconds <= 1) {
        // Trigger endGame one second before timer tick
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  void _onTap() {
    if (isTapping) {
      setState(() => taps++);
    }
  }

  void _endGame() {
    gameTimer?.cancel();
    setState(() => isTapping = false);

    double tapsPerSecond = taps / totalDuration.toDouble();

    // Score (0-5): Based on Taps Per Second (TPS). Target 8 TPS for 5 points.
    double finalScore = (tapsPerSecond / 8.0).clamp(0.0, 1.0) * 5.0;

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: 100.0, // N/A for accuracy
      reactionTime: taps > 0 ? (10000 / taps) : 0, // RT is inverse of speed
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted && taps == 0) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Finger Tapping Rate',
      description: 'Measures pure motor execution speed (dexterity) by tracking the number of taps in a fixed interval.',
      rules: [
        RuleItem('🖐️', 'Action', 'Tap the circle as rapidly as possible when the timer starts.'),
        RuleItem('⏱️', 'Duration', 'The test lasts for 10 seconds.'),
        RuleItem('📈', 'Scoring', 'Score is directly based on your Taps Per Second (TPS).'),
      ],
      onStart: _startGame,
      icon: Icons.touch_app_outlined,
      gradientColors: [themeColor, Colors.blueGrey],
      themeColor: themeColor,
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Finger Tapping Rate'), backgroundColor: themeColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isTapping ? 'Tap as fast as you can!' : 'Test Complete', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Time: ${remainingSeconds}s', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
            const SizedBox(height: 50),

            // Tapping Area
            GestureDetector(
              onTap: _onTap,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  color: isTapping ? themeColor.withOpacity(0.3) : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor, width: 5),
                ),
                child: Center(
                  child: Text(isTapping ? '$taps' : 'Taps: $taps', style: TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: themeColor)),
                ),
              ),
            ),
            const SizedBox(height: 50),
            if (!isTapping)
              ElevatedButton(onPressed: _startGame, child: const Text('Start 10 Second Test')),
          ],
        ),
      ),
    );
  }
}


// 30. ARITHMETIC SPEED GAME (Mental Calculation, Processing Speed)
class ArithmeticSpeedGame extends StatefulWidget {
  final GameEngine gameEngine;
  const ArithmeticSpeedGame({super.key, required this.gameEngine});
  @override
  State<ArithmeticSpeedGame> createState() => _ArithmeticSpeedGameState();
}

class _ArithmeticSpeedGameState extends State<ArithmeticSpeedGame> {
  final Color themeColor = Colors.deepOrange;
  int num1 = 0;
  int num2 = 0;
  String operator = '+';
  int result = 0;
  bool isResultCorrect = false;

  int correctResponses = 0;
  int incorrectResponses = 0;
  int totalTrials = 0;
  bool gameStarted = false; // Added game state flag

  Timer? trialTimer;
  int remainingSeconds = 45;
  Stopwatch reactionStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    // Do NOT call _startGame here. Let the build method show rules first.
  }

  @override
  void dispose() {
    trialTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      remainingSeconds = 45;
      correctResponses = 0;
      incorrectResponses = 0;
      totalTrials = 0;
    });

    _startNextTrial();
    trialTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (remainingSeconds <= 0) {
        _endGame();
        timer.cancel();
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  void _generateProblem() {
    final random = Random();
    num1 = random.nextInt(10) + 1;
    num2 = random.nextInt(10) + 1;

    // Ensure num1 >= num2 for simple subtraction
    if (num1 < num2) {
      int temp = num1;
      num1 = num2;
      num2 = temp;
    }

    operator = random.nextBool() ? '+' : '-';
    int actualResult = operator == '+' ? num1 + num2 : num1 - num2;

    // Introduce error 25% of the time (the result shown is wrong)
    isResultCorrect = random.nextDouble() > 0.25;

    if (isResultCorrect) {
      result = actualResult;
    } else {
      // Offset the result by 1 or 2
      int offset = random.nextBool() ? 1 : -1;
      result = actualResult + offset;
      // Ensure the false result is not the correct one and is not negative
      if (result == actualResult || result <= 0) {
        result = actualResult + (offset > 0 ? 2 : -2);
      }
    }
  }

  void _startNextTrial() {
    _generateProblem();
    reactionStopwatch.reset();
    reactionStopwatch.start();
  }

  void _onResponseTap(bool tappedCorrect) {
    if (remainingSeconds <= 0 || !reactionStopwatch.isRunning) return;

    reactionStopwatch.stop();
    int reactionTime = reactionStopwatch.elapsedMilliseconds;

    totalTrials++;
    bool isCorrect = (tappedCorrect == isResultCorrect);

    setState(() {
      if (isCorrect) {
        correctResponses++;
        HapticFeedback.lightImpact();
      } else {
        incorrectResponses++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, reactionTime);
    _startNextTrial();
  }

  void _endGame() {
    trialTimer?.cancel();
    double accuracy = (totalTrials > 0 ? (correctResponses / totalTrials) : 0).clamp(0.0, 1.0) * 100;
    double avgRT = totalTrials > 0 ? reactionStopwatch.elapsedMilliseconds.toDouble() / totalTrials : 1000.0;

    // Score (0-5): Based on throughput (total trials) and accuracy
    double throughputFactor = (totalTrials / 30.0).clamp(0.0, 1.0) * 2.5;
    double accuracyFactor = (accuracy / 100) * 2.5;
    double finalScore = (throughputFactor + accuracyFactor).clamp(0.0, 5.0);

    widget.gameEngine.completeGame(
      score: finalScore,
      accuracy: accuracy,
      reactionTime: avgRT,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Arithmetic Speed Test',
      description: 'Quickly verify if the displayed simple math problem (addition or subtraction) is **TRUE** or **FALSE** within the time limit.',
      rules: [
        RuleItem('🧮', 'Goal', 'Solve the problem mentally and check if the given result is correct.'),
        RuleItem('👆', 'Action', 'Tap TRUE or FALSE as quickly and accurately as possible.'),
        RuleItem('⏱️', 'Scoring', 'Score rewards high throughput (many verified problems per minute) and high accuracy.'),
      ],
      onStart: _startGame,
      icon: Icons.calculate_outlined,
      gradientColors: [themeColor, Colors.orange],
      themeColor: themeColor,
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Arithmetic Speed Test'), backgroundColor: themeColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Time: ${remainingSeconds}s | Correct: $correctResponses | Wrong: $incorrectResponses', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
            const SizedBox(height: 50),

            // Problem Display
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepOrange, width: 3)),
              child: Text(
                '$num1 $operator $num2 = $result',
                style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
            ),

            const SizedBox(height: 50),

            // Response Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildResponseButton('TRUE', true, Colors.green),
                const SizedBox(width: 40),
                _buildResponseButton('FALSE', false, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseButton(String label, bool value, Color color) {
    return ElevatedButton(
      onPressed: () => _onResponseTap(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 20, color: Colors.white)),
    );
  }
}


// --------------------------------------------------------------------------
// ABSTRACT REASONING GAMES (IDs 31-35)
// --------------------------------------------------------------------------

// 31. INDUCTIVE RULE FINDER GAME (Inductive Reasoning)
class InductiveRuleFinderGame extends StatefulWidget {
  final GameEngine gameEngine;
  const InductiveRuleFinderGame({super.key, required this.gameEngine});

  @override
  State<InductiveRuleFinderGame> createState() => _InductiveRuleFinderGameState();
}

class _InductiveRuleFinderGameState extends State<InductiveRuleFinderGame> {
  final Color themeColor = Colors.indigo;
  Pattern? pattern1;
  Pattern? pattern2;
  Pattern? pattern3;

  List<Pattern> options = [];
  int correctAnswerIndex = -1;

  int correctResponses = 0;
  int incorrectResponses = 0;
  bool gameStarted = false;

  final List<ShapeType> shapes = ShapeType.values; // square, triangle, circle
  final List<double> sizes = [1.0, 1.5]; // Small, Large
  // FIX 1: Re-added allColors list which is required for random color generation
  final List<Color> allColors = [Colors.red, Colors.blue, Colors.green];

  @override
  void initState() {
    super.initState();
    // Do NOT call _startNextTrial here.
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      correctResponses = 0;
      incorrectResponses = 0;
    });
    _startNextTrial();
  }

  void _generatePatterns() {
    final random = Random();

    // CRITICAL FIX 2: Define and initialize placeholder color variables locally
    Color placeholderColor = allColors[random.nextInt(allColors.length)];
    List<Color> placeholderColorList = [placeholderColor];

    // Start with a random shape/size
    int startShapeIndex = random.nextInt(shapes.length);
    int startSizeIndex = random.nextInt(sizes.length);

    // FIX 3: Add the color argument (placeholderColorList) to all pattern definitions (A, B, C)
    pattern1 = Pattern([shapes[startShapeIndex]], [sizes[startSizeIndex]], placeholderColorList);

    // Pattern 2 (B)
    int nextShapeIndex = (startShapeIndex + 1) % shapes.length;
    int nextSizeIndex = (startSizeIndex + 1) % sizes.length;
    pattern2 = Pattern([shapes[nextShapeIndex]], [sizes[nextSizeIndex]], placeholderColorList);

    // Pattern 3 (C)
    nextShapeIndex = (nextShapeIndex + 1) % shapes.length;
    nextSizeIndex = (nextSizeIndex + 1) % sizes.length;
    pattern3 = Pattern([shapes[nextShapeIndex]], [sizes[nextSizeIndex]], placeholderColorList);

    // Correct Answer (D)
    int correctShapeIndex = (nextShapeIndex + 1) % shapes.length;
    int correctSizeIndex = (nextSizeIndex + 1) % sizes.length;
    Pattern correctD = Pattern([shapes[correctShapeIndex]], [sizes[correctSizeIndex]], placeholderColorList);

    // FIX 4: Ensure all Pattern calls in the options list have three arguments
    options = [
      correctD,
      // Distractor 1 (Wrong size)
      Pattern([shapes[nextShapeIndex]], [sizes[startSizeIndex]], placeholderColorList),
      // Distractor 2 (Wrong shape)
      Pattern([shapes[nextShapeIndex]], [sizes[nextSizeIndex]], placeholderColorList),
      // Distractor 3 (Wrong everything)
      Pattern([shapes[correctShapeIndex]], [sizes[startSizeIndex]], placeholderColorList),
    ];

    options.shuffle(random);
    correctAnswerIndex = options.indexWhere((p) => p.equals(correctD));
  }

  void _startNextTrial() {
    setState(() {
      _generatePatterns();
    });
  }

  void _onOptionTap(int index) {
    // FIX: Use .equals() for robust comparison
    bool isCorrect = options[index].equals(options[correctAnswerIndex]);

    setState(() {
      if (isCorrect) {
        correctResponses++;
        HapticFeedback.mediumImpact();
      } else {
        incorrectResponses++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, 2000);
    _startNextTrial();
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildShapeWidget(ShapeType type, double size, Color color) {
    IconData icon = type == ShapeType.square ? Icons.square : (type == ShapeType.triangle ? Icons.change_history : Icons.circle);
    // Use size variable for visual difference
    return Icon(icon, size: 40 * size, color: color);
  }

  Widget _buildPatternCell(Pattern? pattern) {
    if (pattern == null || pattern.shapes.isEmpty) return const SizedBox();
    return Container(
      width: 60, height: 60,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple, width: 1)),
      // FIX: Use pattern.colors.first instead of hardcoded Colors.purple in the child widget
      child: Center(child: _buildShapeWidget(pattern.shapes.first, pattern.sizes.first, pattern.colors.first)),
    );
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Inductive Rule Finder',
      description: 'Observe the three given patterns (A → B → C) and induce the underlying sequential rule to predict the fourth pattern (D).',
      rules: [
        RuleItem('👁️', 'Observation', 'The pattern changes based on two rules simultaneously: **Shape** and **Size**. You must find both rules.'),
        RuleItem('🧠', 'Induction', 'Example Rule: Shape cycles (Square, Triangle, Circle, Square...) AND Size alternates (Small, Large, Small, Large...).'),
        RuleItem('👆', 'Prediction', 'Select the option that logically follows the sequence.'),
      ],
      onStart: _startGame,
      icon: Icons.lightbulb_outline,
      // FIX: Replaced shade600 and shade900 with themeColor (base color) and a dark neutral color.
      gradientColors: [themeColor, Colors.black54],
      // FIX: Replaced shade600 with the base themeColor.
      themeColor: themeColor,
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Inductive Rule Finder'), backgroundColor: themeColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Find the rule and predict the next item.', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
            const SizedBox(height: 20),

            // Pattern Series
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPatternCell(pattern1),
                const Text(' → '),
                _buildPatternCell(pattern2),
                const Text(' → '),
                _buildPatternCell(pattern3),
                const Text(' → ?'),
              ],
            ),
            const SizedBox(height: 40),

            // Options
            Wrap(
              spacing: 20, runSpacing: 20,
              children: List.generate(options.length, (index) {
                return GestureDetector(
                  onTap: () => _onOptionTap(index),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.shade200, width: 2)),
                    child: _buildPatternCell(options[index]),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            Text('Correct: $correctResponses | Wrong: $incorrectResponses', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

// 32. DEDUCTIVE SYLLOGISMS GAME (Deductive Reasoning)
class DeductiveSyllogismsGame extends StatefulWidget {
  final GameEngine gameEngine;
  const DeductiveSyllogismsGame({super.key, required this.gameEngine});
  @override
  State<DeductiveSyllogismsGame> createState() => _DeductiveSyllogismsGameState();
}

class _DeductiveSyllogismsGameState extends State<DeductiveSyllogismsGame> {
  final Color themeColor = Colors.lightGreen;
  String premise1 = '';
  String premise2 = '';
  String conclusion = '';
  SyllogismValidity trueValidity = SyllogismValidity.valid;

  int correctResponses = 0;
  int incorrectResponses = 0;
  bool gameStarted = false;

  // Syllogism pool for better variety (Categorical and Conditional)
  final List<Map<String, dynamic>> syllogismPool = [
    // Valid Categorical (All A are B, All B are C -> All A are C)
    {'p1': 'All dogs are mammals.', 'p2': 'All golden retrievers are dogs.', 'c': 'Therefore, all golden retrievers are mammals.', 'valid': SyllogismValidity.valid},
    // Invalid Categorical (Affirming the Consequent)
    {'p1': 'Some cats are black.', 'p2': 'My pet is black.', 'c': 'Therefore, my pet is a cat.', 'valid': SyllogismValidity.invalid},
    // Valid Conditional (Modus Ponens)
    {'p1': 'If the light is green, the car moves.', 'p2': 'The light is green.', 'c': 'Therefore, the car moves.', 'valid': SyllogismValidity.valid},
    // Invalid Conditional (Denying the Antecedent)
    {'p1': 'If the buzzer sounds, the alarm is on.', 'p2': 'The buzzer does not sound.', 'c': 'Therefore, the alarm is not on.', 'valid': SyllogismValidity.invalid},
  ];


  @override
  void initState() {
    super.initState();
    // Do NOT call _startNextTrial here.
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      correctResponses = 0;
      incorrectResponses = 0;
    });
    _startNextTrial();
  }


  void _generateSyllogism() {
    final random = Random();
    Map<String, dynamic> syllogism = syllogismPool[random.nextInt(syllogismPool.length)];

    premise1 = syllogism['p1'];
    premise2 = syllogism['p2'];
    conclusion = syllogism['c'];
    trueValidity = syllogism['valid'];
  }

  void _startNextTrial() {
    setState(() {
      _generateSyllogism();
    });
  }

  void _onResponseTap(SyllogismValidity tappedValidity) {
    bool isCorrect = tappedValidity == trueValidity;

    setState(() {
      if (isCorrect) {
        correctResponses++;
        HapticFeedback.mediumImpact();
      } else {
        incorrectResponses++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, 3000);
    _startNextTrial();
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Deductive Syllogisms Test',
      description: 'Determine if the conclusion logically follows from the premises. You must assume the premises are true, even if they are factually false.',
      rules: [
        RuleItem('📜', 'Premises', 'You will be given two statements (Premises) that you must accept as fact.'),
        RuleItem('🧠', 'Deduction', 'Judge if the third statement (Conclusion) **MUST** logically follow from the first two. If it must, the argument is VALID.'),
        RuleItem('❌', 'Validity vs. Truth', 'A conclusion can be logically VALID even if it is factually UNTRUE (and vice-versa). Focus only on the structure.'),
      ],
      onStart: _startGame,
      icon: Icons.rule_sharp,
      gradientColors: [themeColor, Colors.green.shade800],
      themeColor: themeColor,
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Deductive Syllogisms'), backgroundColor: themeColor),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Determine if the conclusion is logically VALID or INVALID.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // Syllogism Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: themeColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. $premise1', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text('2. $premise2', style: TextStyle(fontSize: 16)),
                    const Divider(color: Colors.grey),
                    Text(conclusion, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildResponseButton('VALID', SyllogismValidity.valid, Colors.green),
                  const SizedBox(width: 40),
                  _buildResponseButton('INVALID', SyllogismValidity.invalid, Colors.red),
                ],
              ),
              const SizedBox(height: 40),
              Text('Correct: $correctResponses | Wrong: $incorrectResponses', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseButton(String label, SyllogismValidity validity, Color color) {
    return ElevatedButton(
      onPressed: () => _onResponseTap(validity),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 20, color: Colors.white)),
    );
  }
}

// 33. VISUAL ANALOGY TEST (Relational Reasoning)
class VisualAnalogyTest extends StatefulWidget {
  final GameEngine gameEngine;
  const VisualAnalogyTest({super.key, required this.gameEngine});
  @override
  State<VisualAnalogyTest> createState() => _VisualAnalogyTestState();
}

class _VisualAnalogyTestState extends State<VisualAnalogyTest> {
  final Color themeColor = Colors.lightBlue;
  final List<ShapeType> allShapes = ShapeType.values;
  final List<Color> allColors = [Colors.red, Colors.blue];

  // Must be initialized with 'late' as they depend on _generateAnalogy()
  late Pattern a;
  late Pattern b;
  late Pattern c;

  List<Pattern> options = [];
  int correctAnswerIndex = -1;

  int correctResponses = 0;
  int incorrectResponses = 0;
  bool gameStarted = false; // Flow control flag

  @override
  void initState() {
    super.initState();
    // Do NOT call _startNextTrial here.
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      correctResponses = 0;
      incorrectResponses = 0;
    });
    _startNextTrial();
  }

  ShapeType _getNextShape(ShapeType current) {
    int index = allShapes.indexOf(current);
    return allShapes[(index + 1) % allShapes.length];
  }

  Color _invertColor(Color current) {
    // Only works for the defined colors [Red, Blue]
    return current == Colors.red ? Colors.blue : Colors.red;
  }

  void _generateAnalogy() {
    final random = Random();

    // --- Transformation T: Next Shape Cycle AND Color Flip ---

    // 1. Setup Pattern A
    ShapeType startA = allShapes[random.nextInt(allShapes.length)];
    Color colorA = allColors[random.nextInt(allColors.length)];
    // FIX: Pass all three lists to Pattern constructor
    a = Pattern([startA], [1.0], [colorA]);

    // 2. Transformation B (Apply T to A)
    ShapeType nextShapeB = _getNextShape(a.shapes.first);
    Color colorB = _invertColor(colorA);
    b = Pattern([nextShapeB], [1.0], [colorB]);

    // 3. Setup Pattern C (Randomized start)
    ShapeType startC = allShapes[random.nextInt(allShapes.length)];
    Color colorC = allColors[random.nextInt(allColors.length)];
    c = Pattern([startC], [1.0], [colorC]);

    // 4. Correct Answer D (Apply T to C)
    ShapeType nextShapeD = _getNextShape(c.shapes.first);
    Color colorD = _invertColor(colorC);
    Pattern correctD = Pattern([nextShapeD], [1.0], [colorD]);

    // 5. Generate options: All must use the three-argument constructor
    options = [
      correctD, // Correct
      Pattern([nextShapeD], [1.0], [colorC]), // Wrong color
      Pattern([c.shapes.first], [1.0], [colorD]), // Wrong shape
      // Random distractor
      Pattern([allShapes[random.nextInt(allShapes.length)]], [1.0], [allColors[random.nextInt(allColors.length)]]),
    ];

    options.shuffle(random);
    // FIX: Use .equals() for robust comparison to find the index
    correctAnswerIndex = options.indexWhere((p) => p.equals(correctD));
  }

  void _startNextTrial() {
    setState(() {
      _generateAnalogy();
    });
  }

  void _onOptionTap(int index) {
    // FIX: Compare tapped option to the correct option object using equals()
    bool isCorrect = options[index].equals(options[correctAnswerIndex]);

    setState(() {
      if (isCorrect) {
        correctResponses++;
        HapticFeedback.mediumImpact();
      } else {
        incorrectResponses++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, 2000);
    _startNextTrial();
  }

  Widget _buildShapeWidget(ShapeType type, Color color) {
    IconData icon = type == ShapeType.square ? Icons.square : (type == ShapeType.triangle ? Icons.change_history : Icons.circle);
    return Icon(icon, size: 40, color: color);
  }

  Widget _buildAnalogyCell(Pattern pattern, {bool isQuestion = false}) {
    // FIX: Safely access first element of lists
    Color itemColor = pattern.colors.first;
    ShapeType itemShape = pattern.shapes.first;

    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), border: Border.all(color: themeColor)),
      child: Center(child: isQuestion ? const Text('?', style: TextStyle(fontSize: 30, color: Colors.lightBlue)) : _buildShapeWidget(itemShape, itemColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Visual Analogy Test',
      description: 'Find the rule that transforms A into B, and apply that *exact* rule to C to find the missing pattern D (A : B :: C : D).',
      rules: [
        RuleItem('👁️', 'Relationship', 'Observe the transformation (change in shape, color, etc.) from pattern A to B.'),
        RuleItem('🧠', 'Application', 'Apply the **same relational rule** to pattern C to determine the correct pattern D.'),
        RuleItem('⚖️', 'Scoring', 'Accuracy and speed determine the score.'),
      ],
      onStart: _startGame,
      icon: Icons.compare_arrows_sharp,
      gradientColors: [themeColor, Colors.blue.shade800],
      themeColor: themeColor,
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Visual Analogy Test'), backgroundColor: themeColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('A is to B, as C is to D?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // Analogy setup: A:B :: C:D
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnalogyCell(a),
                const Text(' : '),
                _buildAnalogyCell(b),
                const Text(' :: '),
                _buildAnalogyCell(c),
                const Text(' : '),
                _buildAnalogyCell(a, isQuestion: true), // The final question mark cell
              ],
            ),
            const SizedBox(height: 40),

            // Options
            Wrap(
              spacing: 20, runSpacing: 20,
              children: List.generate(options.length, (index) {
                // FIX: Access shapes and colors safely from the options list
                Pattern optionPattern = options[index];
                return GestureDetector(
                  onTap: () => _onOptionTap(index),
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: _buildShapeWidget(optionPattern.shapes.first, optionPattern.colors.first)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            Text('Correct: $correctResponses | Wrong: $incorrectResponses', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
// 34. NUMBER PATTERN PREDICTOR GAME (Quantitative Reasoning)
class NumberPatternPredictorGame extends StatefulWidget {
  final GameEngine gameEngine;
  const NumberPatternPredictorGame({super.key, required this.gameEngine});
  @override
  State<NumberPatternPredictorGame> createState() => _NumberPatternPredictorGameState();
}

class _NumberPatternPredictorGameState extends State<NumberPatternPredictorGame> {
  final Color themeColor = Colors.teal;

  List<int> sequence = [];
  int nextValue = 0;

  List<int> options = [];
  int correctAnswerIndex = -1;

  int correctResponses = 0;
  int incorrectResponses = 0;
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    // Do NOT call _startNextTrial here.
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      correctResponses = 0;
      incorrectResponses = 0;
    });
    _startNextTrial();
  }

  void _generateSequence() {
    final random = Random();

    // FIX: Programmatically generate the complex sequence: +A, -B, *C (A=2, B=1, C=3)
    List<int> newSequence = [random.nextInt(5) + 2]; // Start between 2 and 6
    final List<int Function(int)> rules = [
          (n) => n + 2, // +2
          (n) => n - 1, // -1
          (n) => n * 3, // *3
    ];

    int current = newSequence.first;

    // Generate 6 more elements (7 total in sequence)
    for (int i = 0; i < 6; i++) {
      int ruleIndex = i % rules.length; // Cycle through rules
      current = rules[ruleIndex](current);
      newSequence.add(current);
    }

    // The next value (8th element) uses the first rule (+2)
    nextValue = rules[0](current);
    sequence = newSequence;

    options = [
      nextValue,
      nextValue + 1 + random.nextInt(3),
      nextValue - 1 - random.nextInt(3),
      rules[1](current) + 5, // A distractor from the wrong rule
    ];

    options.shuffle(random);
    correctAnswerIndex = options.indexOf(nextValue);
  }

  void _startNextTrial() {
    setState(() {
      _generateSequence();
    });
  }

  void _onOptionTap(int index) {
    bool isCorrect = index == correctAnswerIndex;

    setState(() {
      if (isCorrect) {
        correctResponses++;
        HapticFeedback.mediumImpact();
      } else {
        incorrectResponses++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, 2000);
    _startNextTrial();
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Number Pattern Predictor',
      description: 'Identify the repeating sequence of arithmetic rules to predict the next number in the series.',
      rules: [
        RuleItem('🔢', 'Sequence', 'The sequence of rules is complex and repeating (e.g., +2, -1, *3, +2, -1, *3...).'),
        RuleItem('🧠', 'Induction', 'Determine the repeating cycle of mathematical operations to find the value of the next number.'),
        RuleItem('👆', 'Prediction', 'Select the correct predicted number from the options.'),
      ],
      onStart: _startGame,
      icon: Icons.functions_outlined,
      gradientColors: [themeColor, Colors.green.shade800],
      themeColor: themeColor,
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Number Pattern Predictor'), backgroundColor: themeColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Identify the rule and select the next number.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // Sequence Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.teal)),
              child: Text(
                '${sequence.join(', ')}, ?',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),

            const SizedBox(height: 40),

            // Options
            Wrap(
              spacing: 20, runSpacing: 20,
              children: List.generate(options.length, (index) {
                return _buildOptionButton(options[index], index);
              }),
            ),
            const SizedBox(height: 40),
            Text('Correct: $correctResponses | Wrong: $incorrectResponses', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(int number, int index) {
    return ElevatedButton(
      onPressed: () => _onOptionTap(index),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        minimumSize: const Size(100, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text('$number', style: const TextStyle(fontSize: 24, color: Colors.white)),
    );
  }
}

// 35. BLOCK FOLDING GAME (Spatial Reasoning, Manipulation)
class BlockFoldingGame extends StatefulWidget {
  final GameEngine gameEngine;
  const BlockFoldingGame({super.key, required this.gameEngine});
  @override
  State<BlockFoldingGame> createState() => _BlockFoldingGameState();
}

class _BlockFoldingGameState extends State<BlockFoldingGame> {
  final Color themeColor = Colors.brown;

  // Logic: Display 2D net, find correct 3D representation
  final List<String> symbols = ['A', 'B', 'C', 'D', 'E', 'F'];

  // The net defines the six faces. Face 0 is the base.
  late List<String> currentNetFaces;
  late List<List<String>> options; // List of cubes, where each cube is [Face1, Face2, Face3]

  int correctAnswerIndex = -1;

  int correctResponses = 0;
  int incorrectResponses = 0;
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    // Do NOT call _startNextTrial here.
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      correctResponses = 0;
      incorrectResponses = 0;
    });
    _startNextTrial();
  }

  void _generateProblem() {
    final random = Random();

    // 1. Generate the Net (Assign symbols to 6 faces)
    List<String> shuffledSymbols = List.from(symbols)..shuffle(random);
    currentNetFaces = shuffledSymbols; // [0: Base, 1: Front, 2: Back, 3: Left, 4: Right, 5: Top]

    // 2. Determine Opposite Faces (Crucial for folding logic)
    // Common Net Configuration (Cross shape): [0, 1, 2, 3, 4, 5]
    // 0 is opposite 5 (Top/Bottom)
    // 1 is opposite 2 (Front/Back)
    // 3 is opposite 4 (Left/Right)

    String faceOpposite5 = currentNetFaces[0];
    String faceOpposite2 = currentNetFaces[1];
    String faceOpposite4 = currentNetFaces[3];

    // 3. Generate Options (3 faces visible on the cube)

    // A. Correct Option (Faces must be non-opposite)
    // Show faces 1, 3, 5 (Front, Left, Top)
    List<String> correctCube = [currentNetFaces[1], currentNetFaces[3], currentNetFaces[5]];
    correctCube.shuffle(random);

    // B. Invalid Option 1 (Uses two opposite faces: 0 and 5)
    List<String> invalidOpposite = [currentNetFaces[0], currentNetFaces[5], currentNetFaces[3]];
    invalidOpposite.shuffle(random);

    // C. Invalid Option 2 (Uses two opposite faces: 1 and 2)
    List<String> invalidAdjacent = [currentNetFaces[1], currentNetFaces[2], currentNetFaces[5]];
    invalidAdjacent.shuffle(random);

    options = [correctCube, invalidOpposite, invalidAdjacent];
    options.shuffle(random);
    correctAnswerIndex = options.indexWhere((opt) => opt.contains(correctCube[0]) && opt.contains(correctCube[1]) && opt.contains(correctCube[2]));

    // Fallback if shuffle makes index inconsistent (Rare but safe)
    if (correctAnswerIndex == -1) {
      // If the find fails, reset and try again (for stability)
      _generateProblem();
      return;
    }
  }

  void _startNextTrial() {
    setState(() {
      _generateProblem();
    });
  }

  void _onOptionTap(int index) {
    bool isCorrect = index == correctAnswerIndex;

    setState(() {
      if (isCorrect) {
        correctResponses++;
        HapticFeedback.mediumImpact();
      } else {
        incorrectResponses++;
        HapticFeedback.heavyImpact();
      }
    });

    widget.gameEngine.recordTrial(isCorrect, 2500);
    _startNextTrial();
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildRulesScreen();
    return _buildGameScreen();
  }

  Widget _buildRulesScreen() {
    return _buildGenericRulesScreen(
      title: 'Block Folding Challenge',
      description: 'Mentally fold the 2D net into a 3D cube and determine which of the options shows a valid view of the resulting block.',
      rules: [
        RuleItem('📏', 'The Net', 'The 2D display shows the unfolded faces of a six-sided cube.'),
        RuleItem('🧠', 'Folding Rule', 'Faces that are separated by one other face on the net are **opposite** and can never be seen together in a 3D view.'),
        RuleItem('👆', 'Selection', 'Select the cube option where the three visible faces are all **adjacent** on the net.'),
      ],
      onStart: _startGame,
      icon: Icons.auto_mode_outlined,
      gradientColors: [Colors.brown.shade600, Colors.grey.shade800],
      themeColor: Colors.brown.shade600,
    );
  }

  Widget _buildNetDisplay() {
    // Displays the net as a cross shape (6 faces)
    // Net:   [3] [0] [4] [5]
    // Base:  [1]
    // Top:   [2]

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFaceCell(currentNetFaces[3], isSide: true),
            _buildFaceCell(currentNetFaces[1]), // Face 1 (Front)
            _buildFaceCell(currentNetFaces[4], isSide: true),
          ],
        ),
        _buildFaceCell(currentNetFaces[0], isSide: true), // Face 0 (Base)
        _buildFaceCell(currentNetFaces[2], isSide: true),
        _buildFaceCell(currentNetFaces[5], isSide: true),
      ],
    );
  }

  Widget _buildFaceCell(String symbol, {bool isSide = false}) {
    return Container(
      width: 40, height: 40,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(color: isSide ? Colors.brown.shade100 : Colors.white, border: Border.all(color: Colors.brown, width: 1)),
      child: Center(child: Text(symbol, style: TextStyle(fontSize: 18, color: Colors.brown))),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Block Folding (Rotation)'), backgroundColor: themeColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Which cube can be formed by folding the net?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // 2D Net Display
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: themeColor, width: 3)),
              child: _buildNetDisplay(),
            ),

            const SizedBox(height: 40),

            // Options (3D Cube Views)
            Wrap(
              spacing: 20, runSpacing: 20,
              children: List.generate(options.length, (index) {
                return _buildCubeOption(index: index, faces: options[index]);
              }),
            ),
            const SizedBox(height: 40),
            Text('Correct: $correctResponses | Wrong: $incorrectResponses', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildCubeOption({required int index, required List<String> faces}) {
    // This widget simulates a 3D view of the cube by showing three adjacent faces (Top, Front, Right side).

    // Assuming faces[0]=Top, faces[1]=Front, faces[2]=Right
    // NOTE: This visual representation is simplified.

    return GestureDetector(
      onTap: () => _onOptionTap(index),
      child: Container(
        width: 120, height: 120,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: themeColor)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Face (Faces[0])
            _buildOptionFace(faces[0], Colors.brown.shade300),
            // Front and Right Face (Faces[1] and Faces[2])
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOptionFace(faces[1], Colors.white), // Front
                _buildOptionFace(faces[2], Colors.brown.shade200), // Right Side
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionFace(String symbol, Color color) {
    return Container(
      width: 40, height: 40,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black12, width: 1)),
      child: Center(child: Text(symbol, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
    );
  }
}
