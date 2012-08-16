require 'spec_helper'
require 'tempfile'

describe "dflat" do
  context "Dflat home" do
    before(:each) do
      t = Tempfile.new 'dflat'
      d = File.dirname t.path

      FileUtils.rm_rf File.join(d, 'test')
      @dflat = Dflat::Home.mkdir File.join(d, 'test')
    end

    it "should contain core files" do
      files = []
      Dir.chdir(@dflat.path) do
        files = Dir.glob(File.join('**', '*'))
      end

      files.should include('0=dflat_0.19', 'current.txt', 'dflat-info.txt', 'v001', 'v001/full/0=dnatural_0.17')
    end

    it "should point to versioned content" do
      File.basename(@dflat.current.path).should == 'v001'
      File.read(File.join(@dflat.path, 'current.txt')).should == 'v001'
    end


    it "should have dflat info" do
      info = @dflat.info
      info[:objectScheme].should == 'Dflat/0.19'
    end

    it "should update dflat info" do
      info = @dflat.info
      info[:test] = 'abcdef'
      @dflat.info = info
      info = @dflat.info
      info[:test].should == 'abcdef'
    end

    it "should add file to current version" do
      file = @dflat.current.add 'LICENSE.txt', 'producer/abcdef'
      lines = @dflat.current.manifest!.to_s.split "\n"
      lines[0].should == '#%checkm_0.7'
      lines[1].should =~ /provider\/abcdef/
      @dflat.current.manifest.should be_valid
    end

    it "should remove file from current version" do
      file = @dflat.current.add 'LICENSE.txt', 'producer/abcdef'
      @dflat.current.remove 'producer/abcdef'
      lines = @dflat.current.manifest!.to_s.split "\n"
      lines.should have(1).line
      lines[0].should == '#%checkm_0.7'
    end

    it "should do basic dnatural versioning" do
      version = @dflat.checkout

                  
      @dflat.commit

      File.basename(@dflat.current.path).should == 'v002'
      File.read(File.join(@dflat.path, 'current.txt')).should == 'v002'
    end

    it "should handle ReDD versioning" do

      previous = @dflat.current
      version = @dflat.checkout
      @dflat.commit!
      
      File.exists?(File.join(previous.path, 'delta')).should == true
    end

    it "should handle ReDD adds" do

      previous = @dflat.current
      version = @dflat.checkout
      version.add 'LICENSE.txt', 'producer/abcdef'
      @dflat.commit!
      
      File.exists?(File.join(previous.path, 'delta')).should == true
      File.read(File.join(previous.path, 'delta', 'delete.txt')).should == 'producer/abcdef'
    end

    it "should handle ReDD removes" do
      previous = @dflat.current
      previous.add 'LICENSE.txt', 'producer/abcdef'
      version = @dflat.checkout
      version.remove 'producer/abcdef'
      @dflat.commit!
      
      File.exists?(File.join(previous.path, 'delta', 'add', 'producer', 'abcdef')).should == true
    end

    it "should handle ReDD modifies" do
      previous = @dflat.current
      previous.add 'LICENSE.txt', 'producer/abcdef'
      version = @dflat.checkout
      version.add 'README.rdoc', 'producer/abcdef'
      @dflat.commit!
      
      File.exists?(File.join(previous.path, 'delta', 'add', 'producer', 'abcdef')).should == true
      File.read(File.join(previous.path, 'delta', 'delete.txt')).should == 'producer/abcdef'
    end

  end
end
