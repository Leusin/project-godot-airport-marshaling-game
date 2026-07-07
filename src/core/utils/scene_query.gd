extends RefCounted
## 씬 트리 그룹 조회 유틸. 그룹 기반 단일 인스턴스 참조를 안전하게 얻는다.
## 여러 스크립트에 흩어져 있던 "그룹 조회 + 널 처리 + 싱글턴 가정"을 한 곳에 모은다.

## group에 노드가 정확히 하나 있다고 가정하고 반환한다.
##  - 없으면 null + 경고 (씬 구성 실수를 드러냄)
##  - 2개 이상이면 첫 번째 + 경고 (싱글턴 가정 위반을 드러냄)
static func require_single(group: StringName) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var nodes := tree.get_nodes_in_group(group)
	if nodes.is_empty():
		push_warning("'%s' 그룹 노드를 찾지 못함 (씬에 하나 있어야 함)." % group)
		return null
	if nodes.size() > 1:
		push_warning("'%s' 그룹에 노드가 %d개 (하나만 있어야 함). 첫 번째를 사용." % [group, nodes.size()])
	return nodes[0]
