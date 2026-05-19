import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

void showCalculator(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _CalculatorSheet(),
  );
}

class _CalculatorSheet extends StatefulWidget {
  const _CalculatorSheet();

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  String _expression = '';
  String _display = '0';
  bool _justCalculated = false;

  void _onButton(String val) {
    setState(() {
      if (val == 'C') {
        _expression = '';
        _display = '0';
        _justCalculated = false;
        return;
      }

      if (val == '⌫') {
        if (_justCalculated) {
          _expression = '';
          _display = '0';
          _justCalculated = false;
          return;
        }
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _display = _expression.isEmpty ? '0' : _expression;
        }
        return;
      }

      if (val == '=') {
        if (_expression.isEmpty) return;
        try {
          final result = _evaluate(_expression);
          _display = _formatResult(result);
          _expression = _display;
          _justCalculated = true;
        } catch (_) {
          _display = 'Erro';
          _expression = '';
          _justCalculated = false;
        }
        return;
      }

      final isOperator = val == '+' || val == '-' || val == '×' || val == '÷';

      if (_justCalculated && !isOperator) {
        _expression = val;
        _display = val;
        _justCalculated = false;
        return;
      }
      _justCalculated = false;

      _expression += val;
      _display = _expression;
    });
  }

  double _evaluate(String expr) {
    // Replace display operators with actual ones
    final normalized = expr.replaceAll('×', '*').replaceAll('÷', '/');

    // Simple left-to-right evaluation with proper precedence using split
    // Parse tokens
    final tokens = <String>[];
    String current = '';
    for (int i = 0; i < normalized.length; i++) {
      final c = normalized[i];
      if ((c == '+' || c == '-' || c == '*' || c == '/') &&
          current.isNotEmpty) {
        tokens.add(current);
        tokens.add(c);
        current = '';
      } else if (c == '-' && current.isEmpty && tokens.isEmpty) {
        current = '-';
      } else {
        current += c;
      }
    }
    if (current.isNotEmpty) tokens.add(current);

    if (tokens.isEmpty) return 0;

    // First pass: multiplication and division
    final pass1 = <String>[tokens.first];
    for (int i = 1; i < tokens.length - 1; i += 2) {
      final op = tokens[i];
      final right = double.parse(tokens[i + 1]);
      if (op == '*') {
        pass1[pass1.length - 1] =
            (double.parse(pass1.last) * right).toString();
      } else if (op == '/') {
        pass1[pass1.length - 1] =
            (double.parse(pass1.last) / right).toString();
      } else {
        pass1.add(op);
        pass1.add(tokens[i + 1]);
      }
    }

    // Second pass: addition and subtraction
    double result = double.parse(pass1.first);
    for (int i = 1; i < pass1.length - 1; i += 2) {
      final op = pass1[i];
      final right = double.parse(pass1[i + 1]);
      if (op == '+') result += right;
      if (op == '-') result -= right;
    }
    return result;
  }

  String _formatResult(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    final s = v.toStringAsFixed(10);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _copyResult() {
    Clipboard.setData(ClipboardData(text: _display));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Valor copiado!'),
        backgroundColor: AppColors.income,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Display
            GestureDetector(
              onTap: _copyResult,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_expression.isNotEmpty && _expression != _display)
                      Text(
                        _expression,
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _display,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.copy_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(width: 4),
                        Text(
                          'toque para copiar',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Buttons grid
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    const buttons = [
      ['C', '⌫', '÷', '×'],
      ['7', '8', '9', '-'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', '', '.', ''],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: row.map((label) {
              if (label.isEmpty) return const Expanded(child: SizedBox());
              final isZero = label == '0';
              return Expanded(
                flex: isZero ? 2 : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CalcButton(
                    label: label,
                    onTap: () => _onButton(label),
                    isOperator: '÷×-+='.contains(label),
                    isEquals: label == '=',
                    isClear: label == 'C',
                    isBackspace: label == '⌫',
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isEquals;
  final bool isClear;
  final bool isBackspace;

  const _CalcButton({
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isEquals = false,
    this.isClear = false,
    this.isBackspace = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (isEquals) {
      bg = AppColors.accent;
      fg = Colors.black;
    } else if (isClear) {
      bg = AppColors.expense.withValues(alpha: 0.15);
      fg = AppColors.expense;
    } else if (isBackspace) {
      bg = const Color(0xFF272727);
      fg = Colors.white70;
    } else if (isOperator) {
      bg = const Color(0xFF6B35FF).withValues(alpha: 0.15);
      fg = const Color(0xFF9B70FF);
    } else {
      bg = const Color(0xFF1C1C1C);
      fg = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isEquals
                  ? Colors.transparent
                  : const Color(0xFF272727).withValues(alpha: 0.5)),
        ),
        child: Center(
          child: isBackspace
              ? Icon(Icons.backspace_outlined, color: fg, size: 20)
              : Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 22,
                    fontWeight: isEquals || isOperator
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
        ),
      ),
    );
  }
}
