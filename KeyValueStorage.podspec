Pod::Spec.new do |s|
  s.name         = "KeyValueStorage"
  s.version      = "0.1.0"
  s.summary      = "Thread-safe key-value storage framework with efficient prefix search"
  s.description  = <<-DESC
                   A protocol-based key-value storage framework for iOS, macOS, and watchOS.
                   Features CRUD operations, efficient prefix search via radix tree,
                   and full thread-safety with Swift 6 strict concurrency.
                   DESC
  s.homepage     = "https://github.com/askopin/key-value-storage"
  s.license      = { :type => "MIT" }
  s.author       = { "Anton Skopin" => "askopin@gmail.com" }
  s.source       = { :git => "https://github.com/askopin/KeyValueStorage.git", :tag => s.version }

  s.ios.deployment_target = "16.0"
  s.osx.deployment_target = "13.0"

  s.swift_version = "6.0"
  s.source_files = "KeyValueStorage/Sources/**/*.swift"

  s.frameworks = "Foundation"
end
