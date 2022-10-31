
=begin
Modify the file so that only comments inside the magic block
between "#pre" and "#endpre" are preprocessed.
The following does nothing:
#define __ONE 1

But the following will be processed:
#pre
#define __ONE 1
#endpre

Input:
inf   Input file (string)
outf  Output file (string)
=end
def prepfile(inf, outf)
  random = Random.new
  File.open(outf, 'a') do |output|
    #output.puts gen_ifndef_name(inf,random)
    doprocess = false
    File.foreach(inf) do |line|
      if line.strip == '#pre'
        doprocess = true
      elsif line.strip == '#endpre'
        doprocess = false
      elsif !doprocess && line.strip.start_with?('#')
        # Do nothing
      else
        output.print line
      end
    end
    #output.puts "#endif"
  end
end

def gen_ifndef_name(fname,random)
  "#ifndef SOURCE#{fname[0..1].upcase}#{random.rand(0x7BADDCAFE)}"
end

# Fetch arguments
input = ARGV.shift # Input main file
output = ARGV.shift # Output file
compiler = ARGV.shift # Preprocessor provider like gcc or clang
interpreter = ARGV.shift # Ruby interpreter (optional)

# Files that will not be preprocessed
BLACKLIST = [__FILE__, output]

output_dir = "./#{__FILE__}_out"

# Clear output directory if it exists or create it if not
if File.exist? output_dir
  Dir[output_dir+'/*'].each do |of|
    File.delete of
  end
else
  Dir.mkdir output_dir
end

# Collect .rb files which are not on the blacklist
rbfiles = Dir['*.rb']
rbfiles += Dir['*.h']
rbfiles.reject! { |f| BLACKLIST.include? f }

rbfiles.each do |f|
  prepfile f, output_dir+"/#{f}"
end

# Move preprocessed main file to output.rb
system "#{compiler} -xc -E #{output_dir}/#{input}.rb -o #{output_dir}/_#{input}.rb"
File.rename "#{output_dir}/_#{input}.rb", "#{output_dir}/#{output}.rb"

# Run script only if an interpreter was specified
if !!interpreter
  # Run the main file
  begin
    system "#{interpreter} #{output_dir}/#{output}.rb #{ARGV.join(" ")}"
  end

  # Delete files
  Dir["#{output_dir}/*"].each do |of|
    File.delete of
  end
  Dir.delete output_dir
end

