import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/shared/utils/responsive_helper.dart';
import 'package:inscripcion_frontend/shared/widgets/app_ui_kit.dart';

class ScheduleGridView extends StatelessWidget {
  final List<dynamic> materias;
  final bool isLarge;

  ScheduleGridView({super.key, required this.materias, this.isLarge = true});

  final List<Color> _subjectColors = [
    const Color(0xFF16A34A), // Verde
    const Color(0xFF3B82F6), // Azul
    const Color(0xFFF59E0B), // Naranja
    const Color(0xFFDC2626), // Rojo
    const Color(0xFF8B5CF6), // Violeta
    const Color(0xFFEC4899), // Rosa
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF84CC16), // Lima
  ];

  final List<String> _days = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB'];
  final List<String> _dayFull = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  
  final Map<String, int> _dayIndex = {
    'L': 0, 'M': 1, 'X': 2, 'J': 3, 'V': 4, 'S': 5
  };

  final List<String> _timeSlots = [
    '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', 
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', 
    '19:00', '20:00', '21:00', '22:00'
  ];

  @override
  Widget build(BuildContext context) {
    if (materias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.today_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No hay materias inscritas', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Confirma tu inscripción para ver el horario.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final Map<String, Color> colorMap = {};
    for (int i = 0; i < materias.length; i++) {
      final codigo = (materias[i]['materia'] as Map<String, dynamic>?)?['codigo'] as String? ?? '';
      colorMap[codigo] = _subjectColors[i % _subjectColors.length];
    }

    final Map<int, Map<int, Map<String, String>>> grid = {};

    for (final item in materias) {
      final matMap = item['materia'] as Map<String, dynamic>? ?? {};
      final ofMap = item['oferta'] as Map<String, dynamic>? ?? {};
      final codigo = matMap['codigo'] as String? ?? '';
      final nombre = matMap['nombre'] as String? ?? '';
      final grupo = ofMap['grupo'] as String? ?? '';
      final horario = ofMap['horario'] as String? ?? '';
      _parseHorario(horario, codigo, nombre, grupo, grid);
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(materias, colorMap),
        const SizedBox(height: 16),
        _buildGrid(grid, colorMap),
      ],
    );

    if (isLarge) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: content,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: content,
    );
  }

  void _parseHorario(String horario, String codigo, String nombre, String grupo, Map<int, Map<int, Map<String, String>>> grid) {
    if (horario.isEmpty) return;
    final parts = horario.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final spaceIdx = trimmed.indexOf(' ');
      if (spaceIdx < 0) continue;

      final dias = trimmed.substring(0, spaceIdx).trim().toUpperCase();
      final horaStr = trimmed.substring(spaceIdx + 1).trim();
      final horaRange = horaStr.replaceAll(':', '');
      final dashIdx = horaRange.indexOf('-');
      if (dashIdx < 0) continue;

      final startRaw = horaRange.substring(0, dashIdx).trim();
      if (startRaw.length < 3) continue;

      int startHour;
      try {
        final hoursStr = startRaw.length >= 4 ? startRaw.substring(0, 2) : startRaw.substring(0, 1);
        startHour = int.parse(hoursStr);
      } catch (_) {
        continue;
      }

      final slotKey = '${startHour.toString().padLeft(2, '0')}:00';
      final slotIdx = _timeSlots.indexOf(slotKey);

      for (final dayChar in dias.split('')) {
        final dayIdx = _dayIndex[dayChar];
        if (dayIdx == null) continue;

        grid[dayIdx] ??= {};
        grid[dayIdx]![slotIdx >= 0 ? slotIdx : startHour - 7] = {
          'codigo': codigo,
          'nombre': nombre,
          'grupo': grupo,
        };
      }
    }
  }

  Widget _buildLegend(List<dynamic> materias, Map<String, Color> colorMap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: materias.map((item) {
        final matMap = item['materia'] as Map<String, dynamic>? ?? {};
        final codigo = matMap['codigo'] as String? ?? '';
        final nombre = matMap['nombre'] as String? ?? '';
        final color = colorMap[codigo] ?? UAGRMTheme.primaryBlue;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text('$codigo — $nombre', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(Map<int, Map<int, Map<String, String>>> grid, Map<String, Color> colorMap) {
    return AppTableCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Column(
            children: [
              _buildHeaderRow(),
              const Divider(height: 1, thickness: 1),
              ...List.generate(_timeSlots.length, (slotIdx) {
                return _buildTimeRow(slotIdx, grid, colorMap);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return AppTableHeader(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(
          width: 60,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Text('HORA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
          ),
        ),
        ..._days.asMap().entries.map((e) => SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
              ),
            )),
      ],
    );
  }

  Widget _buildTimeRow(int slotIdx, Map<int, Map<int, Map<String, String>>> grid, Map<String, Color> colorMap) {
    final isEven = slotIdx % 2 == 0;
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(_timeSlots[slotIdx], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: UAGRMTheme.textGrey), textAlign: TextAlign.center),
            ),
          ),
          ...List.generate(_days.length, (dayIdx) {
            final cellData = grid[dayIdx]?[slotIdx];
            if (cellData == null) return const SizedBox(width: 130, height: 52);

            final codigo = cellData['codigo'] ?? '';
            final nombre = cellData['nombre'] ?? '';
            final grupo = cellData['grupo'] ?? '';
            final color = colorMap[codigo] ?? UAGRMTheme.primaryBlue;

            return Container(
              width: 130,
              margin: const EdgeInsets.all(1),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                color: color,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(codigo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (grupo.isNotEmpty)
                    Text(grupo, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
