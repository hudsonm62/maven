# ziro's maven

Maven repository hosted on GitHub Pages, primarily for my personal projects like Minecraft mods.

## Usage

```gradle
repositories {
    maven("https://maven.ziroau.com")
}

dependencies {
    modImplementation "com.ziroau:mycoolmod:${project.mycoolmod_version}"
}
```
