import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// REGLA DE ORO: Ninguna tabla debe tener scroll horizontal.
/// Este archivo centraliza la lógica para forzar que todo quepa en pantalla.

/// Un contenedor maestro que OBLIGA al contenido a no pasarse del ancho de pantalla.
class StandardTableContainer extends StatelessWidget {
  final Widget child;

  const StandardTableContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
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
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Texto estandarizado para celdas: Forzado a 2 líneas y puntos suspensivos.
class StandardHeaderCell extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const StandardHeaderCell(this.text, {super.key, this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 400;
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        fontSize: isMobile ? 10 : 13,
        color: Colors.white,
        letterSpacing: isMobile ? 0.3 : 0.5,
      ),
    );
  }
}

/// Helper global para textos de celdas con reglas estrictas de no-desbordamiento.
Widget tableText(String text, bool isMobile, {bool bold = false, Color? color}) {
  return Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    softWrap: true,
    style: GoogleFonts.outfit(
      fontSize: isMobile ? 11 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: color ?? UAGRMTheme.textDark,
      height: 1.2,
    ),
  );
}

/// Helper para paddings responsivos obligatorios.
EdgeInsets cellPadding(bool isMobile) {
  return EdgeInsets.symmetric(
    horizontal: isMobile ? 6 : 16,
    vertical: isMobile ? 8 : 14,
  );
}

/// Encabezado flexible que usa Expanded para evitar desbordamientos.
class StandardFlexHeader extends StatelessWidget {
  final List<String> labels;
  final List<int> flexValues;

  const StandardFlexHeader({
    super.key,
    required this.labels,
    required this.flexValues,
  }) : assert(labels.length == flexValues.length);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 400;
    return Container(
      padding: cellPadding(isMobile),
      decoration: const BoxDecoration(
        color: UAGRMTheme.sidebarDeep,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(labels.length, (index) {
          return Expanded(
            flex: flexValues[index],
            child: StandardHeaderCell(labels[index]),
          );
        }),
      ),
    );
  }
}

/// Fila flexible que usa Expanded para forzar el ajuste al ancho de pantalla.
class StandardFlexRow extends StatelessWidget {
  final List<Widget> cells;
  final List<int> flexValues;
  final bool isLast;

  const StandardFlexRow({
    super.key,
    required this.cells,
    required this.flexValues,
    this.isLast = false,
  }) : assert(cells.length == flexValues.length);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 400;
    return Container(
      padding: cellPadding(isMobile),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
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

/// Implementación de Tabla Responsiva que NUNCA usa anchos fijos.
class AppResponsiveTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final Map<int, TableColumnWidth>? customColumnWidths;

  const AppResponsiveTable({
    super.key,
    required this.headers,
    required this.rows,
    this.customColumnWidths,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 400;

    return StandardTableContainer(
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: customColumnWidths ?? {
          for (int i = 0; i < headers.length; i++) i: const FlexColumnWidth(),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: UAGRMTheme.sidebarDeep),
            children: headers.map((l) {
              return TableCell(
                child: Padding(
                  padding: cellPadding(isMobile),
                  child: StandardHeaderCell(l),
                ),
              );
            }).toList(),
          ),
          ...rows.map((rowCells) => TableRow(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            children: rowCells.map((cell) {
              return TableCell(
                child: Padding(
                  padding: cellPadding(isMobile),
                  child: cell,
                ),
              );
            }).toList(),
          )),
        ],
      ),
    );
  }
}

