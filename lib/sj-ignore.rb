require 'github_api'
require 'open-uri'

module SJIgnore
  class Builder
    def initialize(list, langs)
      contents = gh_load

      # Print out a list of all available .gitignore files
      if list
        contents.each do |path, ref|
          p path
        end
      end

      # Begin fetching each .gitignore file requested
      if langs
        ignores = []

        # Fetch each file
        langs.each do |name|
          # Check if the requested language/platform is available in the list of
          # known .gitignore files
          if contents.include? name.downcase
            ref = contents[name]

            # Download the file
            open(ref.download_url, 'rb') do |file|
              content = file.read

              # Append the separator header before adding it to the downloaded list
              content = header(ref.path.split('/').last) + content

              ignores << content
            end
          else
            STDERR.puts "Cannot find a .gitignore file for: #{name}"
          end
        end

        # Join all .gitignore files together and print them to console
        print ignores.join "\n"
      end
    end

    def gh_load
      # Create an interface with github's repo of gitignore files and pull a list of
      # all of them
      github = Github.new
      contents_top = github.repos.contents.get user: 'github', repo: 'gitignore', path: '/'
      contents_global = github.repos.contents.get user: 'github', repo: 'gitignore', path: '/Global'
      contents = {}

      # Filter out all non-gitignore files and add them to a lookup map
      content_filter = Proc.new do |ref|
        if ref.path.include? '.gitignore'
          # Remove any possible path components and grab only the platform or
          # language part of the file name, which will be used later
          name = ref.path.split('/').last.split('.').first.downcase

          contents[name] = ref
        end
      end

      # Combine the two different directories of .gitignore files
      contents_top.each(&content_filter)
      contents_global.each(&content_filter)

      contents
    end

    # This just generates a custom header used to separate the different
    # .gitignore files once they are merged
    def header(lang)
      head =  "#" * 80    + "\n"
      head += "# #{lang}" + "\n"
      head += "#" * 80    + "\n"
      head += "\n"
    end
  end
end