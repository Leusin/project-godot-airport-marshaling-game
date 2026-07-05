# 단위 테스트 실행 헬퍼.
# tests/tests.tscn 을 헤드리스로 돌려 결과를 콘솔에 출력하고, 실패 개수를 종료 코드로 반환한다.
#
# 사용:  ./run_tests.ps1
#
# 참고: Windows용 Godot 에디터 실행 파일은 GUI 프로그램이라, 대화형 콘솔에 직접 실행하면
#       print 로그가 안 보인다. 여기서는 Start-Process -RedirectStandardOutput 으로 stdout을
#       파일에 받아 다시 출력한다 (이 방식만 GUI 빌드 출력을 안정적으로 캡처함).

$ErrorActionPreference = "Stop"
$projectDir = $PSScriptRoot

# Godot 실행 파일: PATH에 있으면 그걸, 없으면 Steam 기본 설치 경로. 다르면 아래 경로만 수정.
$godot = (Get-Command godot -ErrorAction SilentlyContinue).Source
if (-not $godot) {
	$godot = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
}
if (-not (Test-Path $godot)) {
	Write-Error "Godot 실행 파일을 찾지 못했습니다: $godot`nrun_tests.ps1 의 `$godot 경로를 실제 설치 위치로 수정하세요."
	exit 2
}

$outFile = Join-Path $env:TEMP "godot_tests_out.txt"
$errFile = Join-Path $env:TEMP "godot_tests_err.txt"

$proc = Start-Process -FilePath $godot `
	-ArgumentList '--headless', '--path', '.', 'res://tests/tests.tscn' `
	-WorkingDirectory $projectDir -NoNewWindow -Wait -PassThru `
	-RedirectStandardOutput $outFile -RedirectStandardError $errFile

Get-Content $outFile

exit $proc.ExitCode
