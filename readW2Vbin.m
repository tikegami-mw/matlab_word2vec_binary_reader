function emb = readW2Vbin(fileName)
%% readW2Vbin2
%
% This function reads a binary pre-trained word2vec model file. 
%
% Syntax: emb = readW2Vbin2(fileName)
%
% Input:  fileName [string] Path to the word2vec model file to be read
% Output: emb [wordEmbedding] a wordEmbedding object
%
% Note: 
% The code assumes the input file is a binary word2vec format compatible to
% the format used in the file "GoogleNews-vectors-negative300.bin".
% 
% The code DOES NOT provide features for checking size or format of the file. 
%
%
% Copyright (c) 2000 The MathWorks, Inc.
%
%% Open the word2vec file and obtain header inforamtion
%
% Open the file, and read one line, which should contain the number of
% words and number of the dimensions of the embedding vector separated by a
% ' ' (white space). Use |split| function to separate them and put into the
% variable |nWords| and |nDims|.
% 
space  = uint8(' ');  

fid = fopen(fileName,'r');

% The header section of the file consists of "number of words" and "vector
% dimensions" separated by the white space, and delimited by newline.
% (e.g., 3000000\s300\n)  The total number of bytes of this section will
% never exceed 50.
nHeader = 50;

tmpHead = fread(fid,nHeader,'*uint8');
idxSpc = find(tmpHead==space,  1,'first');
idxNewline  = find(tmpHead==newline,1,'first');

nWords = str2double(char(tmpHead(1:idxSpc-1))');
nDims  = str2double(char(tmpHead(idxSpc+1:idxNewline-1))');

% Set the file position to the end of the header section.
fseek(fid,idxNewline,'bof');


%% Prepare arrays and some parameter
%
% Prepare arrays to store the vocabulary (|voc|) and the vector (|mat|)
vocab = repmat("",       [nWords     1]);
mat   = repmat(single(0),[nWords nDims]);

%% 
% Show the progress bar
hw = waitbar(0,'Loadeing word2vec File');

%% Read the body part of the file
% 
% We read the file for a set of "word" and "vector" at one time. The raw
% data read from the file is stored in the temporal array |intData|. Since
% we don't know the length of each word, we read sufficiently large number
% of the data. The parameter |nBuffer| specifies the number of data to be
% read.
%
% At each iteration, there will be some "residue", which is the data
% after the "vector" part. The contents of the "residue" are kept and put
% into the first part of the |intData| at the next iteration, in which we
% read the data |nBuffer| less the length of the "residue" (|nRes|)
%
%%
% Define the additional number of bytes to be read to include both the
% "word" part and the "vector" part of the data, assuming the maximum
% length of the words in the vocabulary is 200. 
nWordBuffer = 200;

nVector = 4*nDims; % assuming the vecotrs are stored in 'single' format
nBuffer = nWordBuffer + nVector;

%% 
% Initialize the temporary variables used in the loop.
intData  = repmat(uint8(0),[nBuffer 1]); 
tmpWord = repmat(uint8(0),[nWordBuffer 1]);
 
residue = []; % Residue of the data from the previous loop
nRes    = 0;  % length of the "residue" data

for kk = 1:nWords
  
  % Read the data from the file 
  readLength = nBuffer-nRes;
  [tmpData, nData] = fread(fid,readLength,'*uint8');
  
  % Put the residue data and the data read from the file into the temprary
  % array.
  intData(1:nRes) = residue;   
  intData(nRes+1:nRes+nData) = tmpData;

  % Find the location of the delimiter of the "word" part (' '). It can
  % also be done with suing "find" function, but it slows down the process
  % a little bit.
  % (e.g.)
  %   wordStopPos = find(intData(1:nWordBuffer)==space,1,'first');
  %   word = intData(1:wordStopPos-1);
  %
  
  % Update |word| until it finds ' ' in the data. Note that the array
  % |word| has the data read during the last iteration.
  wordStopPos = 0;               % Reset the end-point
  for mm = 1:nWordBuffer
    tmpChar = intData(mm);       % Read a byte from the data
    wordStopPos = wordStopPos+1; % Increment the end-point of the "word"
    tmpWord(mm) = tmpChar;       % Update |word| byte-by-byte
    
    if tmpChar==space
      break                      % Break if ' ' is found.
    end
      
  end 
  
  % Split the rest of the data into two parts. "vector", and "residue"  
  vector  = intData(wordStopPos+1:wordStopPos+nVector);
  residue = intData(wordStopPos+nVector+1 :end);
  
  % Update the length of the residue data for the next iteration
  nRes = nBuffer-(wordStopPos+nVector);
  
  % Cast the uint8 into relevant type
  word = tmpWord(1:wordStopPos-1);
  vocab(kk) = char(word)';
  mat(kk,:) = typecast(vector,'single')';
    
  % Update the waitbar
  if mod(kk,100000)==0
    waitbar(kk/nWords,hw,'Loading word2vec File');
  end
  
end

%% Clean-up

close(hw);

fclose(fid);

%% Create wordEmbedding object
emb = wordEmbedding(vocab, mat);

end

