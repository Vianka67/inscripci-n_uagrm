import 'package:inscripcion_frontend/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inscripcion_frontend/config/theme/app_theme.dart';
import 'package:inscripcion_frontend/providers/registration_provider.dart';

class SemesterSelectionScreen extends StatefulWidget {
  const SemesterSelectionScreen({super.key});

  @override
  State<SemesterSelectionScreen> createState() => _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends State<SemesterSelectionScreen> {
  final TextEditingController _registerController = TextEditingController();

  @override
  void dispose() {
    _registerController.dispose();
    super.dispose();
  }

  void _submit() {
    final provider = context.read<RegistrationProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (provider.selectedSemester == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un semestre.'),
          backgroundColor: UAGRMTheme.errorRed,
        ),
      );
      return;
    }

    if (_registerController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu registro universitario.'),
          backgroundColor: UAGRMTheme.errorRed,
        ),
      );
      return;
    }

    provider.setStudentRegister(_registerController.text);
    Navigator.pushNamed(context, '/panel');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrationProvider>();
    final career = provider.selectedCareer;
    final int semesterCount = career?.durationSemesters ?? 9;
    final List<String> semesters = List.generate(semesterCount, (i) => 'SEMESTRE ${i + 1}');

    final bool isTabletOrDesktop = Responsive.isTabletOrDesktop(context);
    if (isTabletOrDesktop) return _buildWebLayout(context, provider, career, semesters);
    return _buildMobileLayout(context, provider, career, semesters);
  }

  // ─── WEB LAYOUT ──────────────────────────────────────────────────────────────

  Widget _buildWebLayout(BuildContext context, dynamic provider, dynamic career, List<String> semesters) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header compacto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: UAGRMTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school, color: UAGRMTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Inicio', style: TextStyle(fontSize: 12, color: UAGRMTheme.primaryBlue)),
                            ),
                            const Text(' › ', style: TextStyle(fontSize: 12, color: UAGRMTheme.textGrey)),
                            const Text('Selección de Semestre', style: TextStyle(fontSize: 12, color: UAGRMTheme.textGrey)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          career != null ? career.name : 'Selección de Semestre',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text('Volver', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UAGRMTheme.textGrey,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido centrado
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna izquierda: grid de semestres
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selecciona tu semestre',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Elige el semestre correspondiente a tu avance académico.',
                                style: TextStyle(fontSize: 12, color: UAGRMTheme.textGrey),
                              ),
                              const SizedBox(height: 16),
                              _buildWebGrid(provider, semesters),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Columna derecha: registro + botón
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registro universitario',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ingresa el número de tu carnet universitario.',
                                style: TextStyle(fontSize: 12, color: UAGRMTheme.textGrey),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _registerController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Ej: 2150826',
                                        prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: UAGRMTheme.primaryBlue)),
                                        isDense: true,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: UAGRMTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          elevation: 0,
                                        ),
                                        child: const Text('Continuar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebGrid(dynamic provider, List<String> semesters) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: semesters.length,
      itemBuilder: (context, index) {
        final semester = semesters[index];
        final isSelected = provider.selectedSemester == semester;
        return Material(
          color: isSelected ? UAGRMTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(6),
          elevation: isSelected ? 2 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => context.read<RegistrationProvider>().selectSemester(semester),
            hoverColor: UAGRMTheme.primaryBlue.withValues(alpha: 0.06),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? UAGRMTheme.primaryBlue : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Text(
                  semester,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : UAGRMTheme.textDark,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── MÓVIL: diseño original ───────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, dynamic provider, dynamic career, List<String> semesters) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('UAGRM'),
            if (career != null)
              Text(career.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'SEMESTRE',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: semesters.length,
                itemBuilder: (context, index) {
                  final semester = semesters[index];
                  final isSelected = provider.selectedSemester == semester;
                  return Material(
                    color: isSelected ? UAGRMTheme.primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.read<RegistrationProvider>().selectSemester(semester),
                      child: Center(
                        child: Text(
                          semester,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Registro Universitario',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: UAGRMTheme.textDark)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _registerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Ej: 2150826',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
