/// 온디바이스 LLM 호출 경계. 프롬프트 하나에 응답 문자열 하나.
abstract interface class LlmClient {
  Future<String> generate(String prompt, {required int seed});
}
