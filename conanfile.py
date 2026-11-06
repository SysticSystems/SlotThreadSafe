from conan import ConanFile
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.files import copy, load
import os


class SlotThreadSafeConan(ConanFile):
    name = "slotthreadsafe"
    # Do NOT set version here statically
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeToolchain", "CMakeDeps"

    exports_sources = "CMakeLists.txt", "src/*"

    def set_version(self):
        # 1. First priority: Environment variable from .env / CI
        env_version = os.getenv("PROJECT_VERSION")
        if env_version:
            self.version = env_version.strip()
            return

        # 2. Fallback: Read from central VERSION file in root directory
        version_file = os.path.join(self.recipe_folder, "VERSION")
        if os.path.exists(version_file):
            self.version = load(self, version_file).strip()
            return

        raise RuntimeError(
            "Version could not be resolved. Define 'PROJECT_VERSION' in your environment/.env or create a 'VERSION' file."
        )

    def layout(self):
        cmake_layout(self)

    def build_requirements(self):
        self.test_requires("gtest/1.14.0")
        self.test_requires("benchmark/1.8.3")

    def configure(self):
        self.settings.compiler.cppstd = "23"
        if self.settings.compiler == "clang":
            self.settings.compiler.libcxx = "libstdc++11"

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

        copy(
            self,
            "*.pcm",
            src=self.build_folder,
            dst=os.path.join(self.package_folder, "bmi"),
            keep_path=False,
        )

    def package_info(self):
        self.cpp_info.libs = ["slotthreadsafe"]

        bmi_dir = os.path.join(self.package_folder, "bmi")

        self.cpp_info.cxxflags = [
            f"-fmodule-file=Systic.System.Concurrency={bmi_dir}/Systic.System.Concurrency.pcm",
            f"-fmodule-file=Systic.System.Concurrency:CpuIntrinsics={bmi_dir}/Systic.System.Concurrency-CpuIntrinsics.pcm",
        ]

        self.cpp_info.set_property("cmake_target_name", "arrayslotthreadsafe::arrayslotthreadsafe")