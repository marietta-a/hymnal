import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hymnal/data/hymn_data.dart';
import 'package:hymnal/providers/game_provider.dart';
import 'package:provider/provider.dart';

// ─── Confetti particle ───────────────────────────────────────────────────────

class _Particle {
  final double x0, y0; // normalised start (0–1 fraction of screen)
  final double vx, vy; // normalised velocity per unit time (0→1)
  final Color color;
  final double size;
  final double rotSpeed; // rotations per unit time

  const _Particle({
    required this.x0, required this.y0,
    required this.vx, required this.vy,
    required this.color, required this.size, required this.rotSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0→1 progress

  const _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final fade = t > 0.6 ? (1.0 - (t - 0.6) / 0.4).clamp(0.0, 1.0) : 1.0;
      final x = (p.x0 + p.vx * t) * size.width;
      // gravity: adds downward drift proportional to t²
      final y = (p.y0 + p.vy * t + 0.85 * t * t) * size.height;
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotSpeed * t * pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.45),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ─── Data models ────────────────────────────────────────────────────────────

enum _Phase { intro, playing, answered, gameOver }

enum _QuestionType { nameHymn, findCategory }

class _Question {
  final _QuestionType type;
  final String prompt; // the lyric snippet or hymn title
  final String label; // question label shown above card
  final String correct;
  final List<String> options; // shuffled 4 choices

  const _Question({
    required this.type,
    required this.prompt,
    required this.label,
    required this.correct,
    required this.options,
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _timerCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _celebrationCtrl;

  // Game state
  _Phase _phase = _Phase.intro;
  bool _isNewHigh = false;
  List<_Particle> _particles = [];
  int _lives = 3;
  int _score = 0;
  int _streak = 0;
  int _questionsAnswered = 0;
  _Question? _question;
  String? _selected;

  // Feedback overlay
  String _feedbackText = '';
  Color _feedbackColor = Colors.green;

  static const int _maxLives = 3;
  static const int _base = 100;
  static const Duration _answerDelay = Duration(milliseconds: 900);

  final Random _rng = Random();

  // Cached once — never recomputed on rebuild
  late final List<Map> _hymns;
  late final List<String> _allCategories;

  int get _multiplier {
    if (_streak >= 9) return 4;
    if (_streak >= 6) return 3;
    if (_streak >= 3) return 2;
    return 1;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _hymns = hymnJson.cast<Map>();
    _allCategories =
        _hymns.map((h) => h['category'] as String).toSet().toList();

    _timerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _phase == _Phase.playing) {
          _onTimeout();
        }
      });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.elasticOut),
    );

    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _pulseCtrl.dispose();
    _celebrationCtrl.dispose();
    super.dispose();
  }

  // ── Game logic ─────────────────────────────────────────────────────────────

  void _startGame() {
    setState(() {
      _phase = _Phase.playing;
      _lives = _maxLives;
      _score = 0;
      _streak = 0;
      _questionsAnswered = 0;
      _selected = null;
    });
    _nextQuestion();
  }

  void _nextQuestion() {
    setState(() {
      _question = _buildQuestion();
      _selected = null;
      _phase = _Phase.playing;
    });
    _timerCtrl.forward(from: 0);
  }

  _Question _buildQuestion() {
    final useCategory = _rng.nextBool();

    if (useCategory) {
      // "Which category does [hymn title] belong to?"
      final hymn = _hymns[_rng.nextInt(_hymns.length)];
      final correct = hymn['category'] as String;
      final wrongs = _allCategories
          .where((c) => c != correct)
          .toList()
        ..shuffle(_rng);
      final options = [correct, ...wrongs.take(3)]..shuffle(_rng);
      return _Question(
        type: _QuestionType.findCategory,
        label: 'Which category does this hymn belong to?',
        prompt: 'Hymn ${hymn['number']}\n${_titleCase(hymn['title'] as String)}',
        correct: correct,
        options: options,
      );
    } else {
      // "Which hymn contains this lyric?"
      final hymn = _pickHymnWithGoodLyric();
      final snippet = _extractSnippet(hymn['lyrics'] as String);
      final correct = _titleCase(hymn['title'] as String);
      final wrongs = _hymns
          .where((h) => h['number'] != hymn['number'])
          .map((h) => _titleCase(h['title'] as String))
          .toList()
        ..shuffle(_rng);
      final options = [correct, ...wrongs.take(3)]..shuffle(_rng);
      return _Question(
        type: _QuestionType.nameHymn,
        label: 'Which hymn contains this lyric?',
        prompt: snippet,
        correct: correct,
        options: options,
      );
    }
  }

  Map _pickHymnWithGoodLyric() {
    // Prefer hymns with multi-stanza lyrics
    final candidates = _hymns
        .where((h) =>
            (h['lyrics'] as String).contains('\n\n') &&
            (h['lyrics'] as String).length > 100)
        .toList();
    return candidates.isEmpty
        ? _hymns[_rng.nextInt(_hymns.length)]
        : candidates[_rng.nextInt(candidates.length)];
  }

  String _extractSnippet(String lyrics) {
    final stanzas = lyrics.split('\n\n');
    // Skip antiphons/headers, pick a meaty stanza
    final meaty = stanzas
        .where((s) =>
            s.split('\n').length >= 2 &&
            !s.toLowerCase().startsWith('antiphon'))
        .toList();
    final stanza = (meaty.isEmpty ? stanzas : meaty)[_rng.nextInt(
        (meaty.isEmpty ? stanzas : meaty).length)];

    final lines = stanza
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .where((l) => l.isNotEmpty)
        .take(3)
        .join('\n');

    return '"$lines"';
  }

  String _titleCase(String s) {
    if (s.length <= 30) return s;
    // Truncate long titles for display
    return '${s.substring(0, 28)}…';
  }

  void _onAnswer(String choice) {
    if (_phase != _Phase.playing) return;
    _timerCtrl.stop();
    final correct = choice == _question!.correct;

    setState(() {
      _selected = choice;
      _phase = _Phase.answered;
    });

    if (correct) {
      final earned = _base * _multiplier;
      setState(() {
        _score += earned;
        _streak++;
        _questionsAnswered++;
        _feedbackText = _streak > 1
            ? '+$earned  🔥 $_streak streak!'
            : '+$earned';
        _feedbackColor = Colors.greenAccent.shade400;
      });
      _pulseCtrl.forward(from: 0);
    } else {
      setState(() {
        _lives--;
        _streak = 0;
        _questionsAnswered++;
        _feedbackText = 'Wrong! −1 ❤️';
        _feedbackColor = Colors.redAccent.shade400;
      });
    }

    Future.delayed(_answerDelay, () {
      if (!mounted) return;
      if (_lives <= 0) {
        final prevHigh = context.read<GameProvider>().highScore;
        context.read<GameProvider>().submitScore(_score);
        _isNewHigh = _score > prevHigh && _score > 0;
        setState(() => _phase = _Phase.gameOver);
        if (_isNewHigh) {
          _particles = _generateParticles();
          _celebrationCtrl.forward(from: 0);
        }
      } else {
        _nextQuestion();
      }
    });
  }

  void _onTimeout() {
    if (_phase != _Phase.playing) return;
    setState(() {
      _phase = _Phase.answered;
      _lives--;
      _streak = 0;
      _questionsAnswered++;
      _feedbackText = "Time's up! −1 ❤️";
      _feedbackColor = Colors.orangeAccent.shade400;
    });

    Future.delayed(_answerDelay, () {
      if (!mounted) return;
      if (_lives <= 0) {
        final prevHigh = context.read<GameProvider>().highScore;
        context.read<GameProvider>().submitScore(_score);
        _isNewHigh = _score > prevHigh && _score > 0;
        setState(() => _phase = _Phase.gameOver);
        if (_isNewHigh) {
          _particles = _generateParticles();
          _celebrationCtrl.forward(from: 0);
        }
      } else {
        _nextQuestion();
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF006064), Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: switch (_phase) {
            _Phase.intro => _buildIntro(),
            _Phase.gameOver => _buildGameOver(),
            _ => _buildGame(),
          },
        ),
      ),
    );
  }

  // ── Intro ──────────────────────────────────────────────────────────────────

  Widget _buildIntro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎵', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Hymnal Quiz',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              'How well do you know\nthe Cameroon Hymnal?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 40),
            // High score badge
            if (context.watch<GameProvider>().highScore > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Best: ${context.watch<GameProvider>().highScore} pts',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            // How to play
            _infoCard([
              _infoRow('🎵', 'Name the hymn from a lyric'),
              _infoRow('📂', 'Find the right category'),
              _infoRow('🔥', 'Streaks multiply your score'),
              _infoRow('⏱️', '10 seconds per question'),
              _infoRow('❤️', '3 lives — don\'t lose them!'),
            ]),
            const SizedBox(height: 36),
            FilledButton(
              onPressed: _startGame,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.black,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Start Game'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back',
                  style:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _infoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Game ───────────────────────────────────────────────────────────────────

  Widget _buildGame() {
    final q = _question;
    if (q == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildHeader(),
        _buildTimerBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildQuestionCard(q),
                const SizedBox(height: 16),
                if (_phase == _Phase.answered)
                  _buildFeedbackBanner()
                else
                  const SizedBox(height: 44),
                const SizedBox(height: 8),
                Expanded(child: _buildAnswerGrid(q)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Lives
          Row(
            children: List.generate(
              _maxLives,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: i < _lives ? Colors.redAccent.shade200 : Colors.white30,
                  size: 24,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Streak badge
          if (_streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$_streak  ×$_multiplier',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          // Score
          ScaleTransition(
            scale: _pulseAnim,
            child: Text(
              '$_score',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          Text('pts',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    return AnimatedBuilder(
      animation: _timerCtrl,
      builder: (context, _) {
        final progress = _timerCtrl.value;
        final Color color;
        if (progress > 0.5) {
          color = Colors.redAccent.shade400;
        } else if (progress > 0.25) {
          color = Colors.orangeAccent.shade400;
        } else {
          color = Colors.greenAccent.shade400;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 1.0 - progress,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(_Question q) {
    final isLyric = q.type == _QuestionType.nameHymn;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLyric ? Icons.music_note_rounded : Icons.category_rounded,
                color: Colors.amber.shade300,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  q.label,
                  style: TextStyle(
                      color: Colors.amber.shade200,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                ),
              ),
              Text(
                'Q${_questionsAnswered + 1}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.prompt,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLyric ? 14 : 18,
              fontStyle: isLyric ? FontStyle.italic : FontStyle.normal,
              fontWeight: isLyric ? FontWeight.normal : FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _feedbackColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _feedbackColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _feedbackText,
            style: TextStyle(
                color: _feedbackColor,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerGrid(_Question q) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: q.options
          .map((opt) => _buildAnswerButton(opt, q.correct))
          .toList(),
    );
  }

  Widget _buildAnswerButton(String option, String correct) {
    final isCorrect = option == correct;
    final answered = _phase == _Phase.answered;

    Color bg = Colors.white.withValues(alpha: 0.12);
    Color border = Colors.white.withValues(alpha: 0.3);
    Color textColor = Colors.white;

    if (answered) {
      if (isCorrect) {
        bg = Colors.greenAccent.withValues(alpha: 0.25);
        border = Colors.greenAccent.shade400;
        textColor = Colors.greenAccent.shade200;
      } else if (option == _selected && !isCorrect) {
        bg = Colors.redAccent.withValues(alpha: 0.25);
        border = Colors.redAccent.shade200;
        textColor = Colors.redAccent.shade200;
      }
    }

    return GestureDetector(
      onTap: answered ? null : () => _onAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        child: Text(
          option,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
    );
  }

  // ── Confetti ───────────────────────────────────────────────────────────────

  List<_Particle> _generateParticles() {
    const colors = [
      Color(0xFFFFD700), Color(0xFFFF6B6B), Color(0xFF4ECDC4),
      Color(0xFF45B7D1), Color(0xFFFFA500), Color(0xFFFF69B4),
      Color(0xFF98FB98), Color(0xFFDDA0DD), Color(0xFFFFEC3D),
    ];
    return List.generate(80, (_) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 0.15 + _rng.nextDouble() * 0.3;
      return _Particle(
        x0: 0.05 + _rng.nextDouble() * 0.9,
        y0: 0.05 + _rng.nextDouble() * 0.35,
        vx: cos(angle) * speed * 0.35,
        vy: -(0.15 + _rng.nextDouble() * 0.45),
        color: colors[_rng.nextInt(colors.length)],
        size: 7 + _rng.nextDouble() * 10,
        rotSpeed: (1 + _rng.nextDouble() * 4) * (_rng.nextBool() ? 1 : -1),
      );
    });
  }

  // ── Game Over ──────────────────────────────────────────────────────────────

  Widget _buildGameOver() {
    final highScore = context.read<GameProvider>().highScore;
    final t = _celebrationCtrl.value;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy / emoji
            if (_isNewHigh)
              Transform.scale(
                scale: (t < 0.25
                    ? Curves.elasticOut.transform((t / 0.25).clamp(0.0, 1.0)) * 1.1
                    : 1.0 + sin(t * pi * 5) * 0.04 * (1 - t)).clamp(0.0, 1.4),
                child: const Text('🏆', style: TextStyle(fontSize: 72)),
              )
            else
              Text(_lives <= 0 ? '💔' : '🎉',
                  style: const TextStyle(fontSize: 64)),

            const SizedBox(height: 16),

            // Title with golden shimmer for new high score
            if (_isNewHigh)
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [
                    Color(0xFFFFD700), Color(0xFFFFF176),
                    Color(0xFFFFB300), Color(0xFFFFD700),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                  transform: GradientRotation(t * pi * 6),
                ).createShader(bounds),
                child: const Text(
                  '🌟 New High Score! 🌟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              )
            else
              const Text('Game Over',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _statRow('Score', '$_score pts', Colors.amber.shade300),
                  const SizedBox(height: 12),
                  _statRow('Best', '$highScore pts',
                      _isNewHigh ? Colors.amber.shade300 : Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  _statRow('Answered', '$_questionsAnswered', Colors.lightBlueAccent),
                  const SizedBox(height: 12),
                  _statRow(
                    'Accuracy',
                    _questionsAnswered == 0
                        ? '—'
                        : '${((_questionsAnswered - (_maxLives - _lives)) / _questionsAnswered * 100).round()}%',
                    Colors.greenAccent.shade200,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            FilledButton(
              onPressed: () {
                _isNewHigh = false;
                _celebrationCtrl.reset();
                _startGame();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.black,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Play Again'),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Exit',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15)),
            ),
          ],
        ),
      ),
    );

    if (!_isNewHigh) return content;

    return Stack(
      children: [
        content,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ConfettiPainter(_particles, t),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
