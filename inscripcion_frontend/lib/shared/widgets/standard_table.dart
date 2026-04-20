import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Un contenedor maestro para dotar a las tablas del sistema con la sombra,
/// bordes redondeados y fondo blanco uniforme.
class StandardTableContainer extends StatelessWidget {
  final Widget child;
  final double? minWidth;

  const StandardTableContainer({super.key, required this.child, this.minWidth});

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (minWidth != null) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final double safeMaxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : minWidth!;
          final double targetWidth = safeMaxWidth > minWidth! ? safeMaxWidth : minWidth!;
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: targetWidth,
              child: child,
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

/// Una fila de encabezado genérica con fondo Navy Dark y texto blanco.
/// Especialmente útil para pseudo-tablas hechas con ListView o listados manuales.
class StandardTableHeader extends StatelessWidget {
  final List<Widget> children;

  const StandardTableHeader({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: UAGRMTheme.sidebarDeep, // Navy oscuro (#0B1A2B)
      ),
      child: Row(
        children: children,
      ),
    );
  }
}

/// Encabezado de celda con estilo oficial UAGRM
class StandardHeaderCell extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const StandardHeaderCell(this.text, {super.key, this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Fila de cabecera con fondo Navy Dark
TableRow buildStandardTableRowHeader({required List<String> labels, List<TextAlign>? aligns}) {
  return TableRow(
    decoration: const BoxDecoration(
      color: UAGRMTheme.sidebarDeep,
    ),
    children: labels.asMap().entries.map((entry) {
      final i = entry.key;
      final text = entry.value;
      final align = (aligns != null && i < aligns.length) ? aligns[i] : TextAlign.left;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: StandardHeaderCell(text, textAlign: align),
      );
    }).toList(),
  );
}

/// Envoltura uniforme para DataTable nativo
class StandardDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double columnSpacing;
  final double? minWidth;
  final WidgetStateProperty<Color?>? headingRowColor;
  final double dividerThickness;
  final Widget? topHeading;

  const StandardDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.columnSpacing = 24,
    this.minWidth,
    this.headingRowColor,
    this.dividerThickness = 0.5,
    this.topHeading,
  });

  @override
  Widget build(BuildContext context) {
    return StandardTableContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget table = DataTable(
            headingRowColor: headingRowColor ?? WidgetStateProperty.resolveWith((states) => UAGRMTheme.sidebarDeep),
            headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            dividerThickness: dividerThickness,
            columnSpacing: columnSpacing,
            columns: columns,
            rows: rows,
          );

          if (minWidth != null) {
            table = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth!),
                child: table,
              ),
            );
          }

          if (topHeading != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                topHeading!,
                const Divider(height: 1),
                table,
              ],
            );
          }

          return table;
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  StandardFlexHeader — Encabezado de tabla con proporciones personalizadas
// ─────────────────────────────────────────────────────────────────────────────
class StandardFlexHeader extends StatelessWidget {
  final List<String> labels;
  final List<int> flexValues;

  StandardFlexHeader({
    super.key,
    required this.labels,
    required this.flexValues,
  }) : assert(labels.length == flexValues.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: const Color(0xFF010A13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(labels.length, (index) {
          return Expanded(
            flex: flexValues[index],
            child: Text(
              labels[index].toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StandardFlexRow extends StatelessWidget {
  final List<Widget> cells;
  final List<int> flexValues;
  final bool isLast;

  StandardFlexRow({
    super.key,
    required this.cells,
    required this.flexValues,
    this.isLast = false,
  }) : assert(cells.length == flexValues.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast ? null : Border(bottom: BorderSide(color: const Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(cells.length, (index) {
          return Expanded(
            flex: flexValues[index],
            child: cells[index],
          );
        }),
      ),
    );
  }
}
