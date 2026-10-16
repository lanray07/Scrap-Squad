#include <jni.h>
#include <mutex>
#include <string>
#include <cstring>
extern "C" char* sq_request(const char*);
extern "C" void sq_free(char*);
static std::mutex stateMutex;
extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_scrapsquad_fire_NativeCore_exchange(JNIEnv* env, jobject, jbyteArray input) {
    std::lock_guard<std::mutex> lock(stateMutex);
    const jsize length = env->GetArrayLength(input);
    std::string bytes(length, '\0');
    env->GetByteArrayRegion(input, 0, length, reinterpret_cast<jbyte*>(bytes.data()));
    if (env->ExceptionCheck()) return nullptr;
    char* result = sq_request(bytes.c_str());
    if (!result) return nullptr;
    const auto size = static_cast<jsize>(strlen(result));
    jbyteArray output = env->NewByteArray(size);
    if (output) env->SetByteArrayRegion(output, 0, size, reinterpret_cast<jbyte*>(result));
    sq_free(result);
    return output;
}
