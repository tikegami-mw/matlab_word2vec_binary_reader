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
%% Open the word2vec file and obtain header inforamtion
%
% Open the file, and read one line, which should contain the number of
% words and number of the dimensions of the embedding vector separated by a
% ' ' (white space). Use |split| function to separate them and put into the
% variable |nWords| and |nDims|.

fid = fopen(fileName,'r');

header = fgetl(fid);
tmpTxt = split(header,' ');

nWords = str2double(tmpTxt(1));
nDims  = str2double(tmpTxt(2));

%% Prepare arrays and some parameter
%
% Prepare arrays to store the vocabulary (|voc|) and the vector (|mat|)
voc = repmat("",        [nWords     1]);
mat = repmat(single(0), [nWords nDims]);

%%
% Define the number of bytes to be read to find "vocabulary" part in the
% data, assuming the maximum length of the words in the vocabulary is 200.
nBuffer = 200;

%% 
% Show the progress bar
hw = waitbar(0,'Loadeing word2vec File'); 

%% Process the data word-by-word.
%
for kk = 1:nWords
  %%
  % Read the file for the "vocabulary". Since we don't know the length
  % of each word, we read sufficiently large number of data. (The parameter
  % |nBuffer| specifies the number of data to be read. 
  tmpData = fread(fid,nBuffer,'*uint8');

  %%
  % Then find the delimiter ' ' (white space) to identify the point that
  % separates the word and the vector data.
  wordStopPos = find(tmpData==uint8(' '),1,'first');

  %%
  % Convert the word data into char and transpose so that it can be put
  % into an element of the string array. Note that |tmpData(wordStopPos)|
  % is ' ', which should not be included in the |voc(kk)|
  voc(kk) = char(tmpData(1:wordStopPos-1))';

  %%
  % Now, we discard the "vocabulary" part of the tempData. The remaing part
  % is a part of the "vector" part of the data.
  tmpData = tmpData(wordStopPos+1:end);

  %%
  % Read the vector data. Since we already obtained a part of the data, the
  % total number of Bytes to be read is |4*nDims| minus length of the
  % |tmpData|, which is |nBuffer - wordStopPos|.   
  vector = fread(fid,4*nDims-(nBuffer-wordStopPos),'*uint8');

  %%
  % Combine the |tmpData| and the |vector| read above, and convert the data
  % type into 'single'.
  mat(kk,:) = typecast([tmpData; vector],'single');

  %%
  % Update the progress bar
  if mod(kk,100000)==0
    waitbar(kk/nWords,hw,'Loading word2vec File');
  end
  
end


close(hw); % Close the progress bar

fclose(fid);

%% Construct wordEmbedding object
%
% Finally, construct the |wordEmbedding| object.
emb = wordEmbedding(voc, mat);

end

