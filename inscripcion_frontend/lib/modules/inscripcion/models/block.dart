class Block {
  final int id;
  final String type;
  final String reason;
  final String blockDate;
  final String? estimatedUnblockDate;
  final bool isActive;

  Block({
    required this.id,
    required this.type,
    required this.reason,
    required this.blockDate,
    this.estimatedUnblockDate,
    required this.isActive,
  });

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] ?? 0,
      type: json['tipo'] ?? '',
      reason: json['motivo'] ?? '',
      blockDate: json['fechaBloqueo'] ?? '',
      estimatedUnblockDate: json['fechaDesbloqueoEstimada'],
      isActive: json['activo'] ?? false,
    );
  }
}

class BlockStatus {
  final bool isBlocked;
  final List<Block> blocks;
  final bool canEnroll;
  final String message;

  BlockStatus({
    required this.isBlocked,
    required this.blocks,
    required this.canEnroll,
    required this.message,
  });

  factory BlockStatus.fromJson(Map<String, dynamic> json) {
    final blocksList = json['bloqueos'] as List<dynamic>? ?? [];
    return BlockStatus(
      isBlocked: json['bloqueado'] ?? false,
      blocks: blocksList.map((b) => Block.fromJson(b)).toList(),
      canEnroll: json['puedeInscribirse'] ?? true,
      message: json['mensaje'] ?? '',
    );
  }
}
