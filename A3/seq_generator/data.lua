--
----  Copyright (c) 2014, Facebook, Inc.
----  All rights reserved.
----
----  This source code is licensed under the Apache 2 license found in the
----  LICENSE file in the root directory of this source tree.
----

local stringx = require('pl.stringx') -- PenLight Stringx lib
local file = require('pl.file') -- PenLight file manipulation

local ptb_path = "./data/"

local trainfn = ptb_path .. "ptb.train.txt" 
local testfn  = ptb_path .. "ptb.test.txt"
local validfn = ptb_path .. "ptb.valid.txt"

local vocab_idx = 0 -- vocabulary index
local vocab_map = {} -- word: index mapping 
local inv_vocab_map = {} -- index: word mapping

-- Stacks relicated, shifted versions of x_inp
-- into a single matrix of size x_inp:size(1) x batch_size.
local function replicate(x_inp, batch_size)
    local s = x_inp:size(1)
    local x = torch.zeros(torch.floor(s / batch_size), batch_size)
    for i = 1, batch_size do
        local start = torch.round((i - 1) * s / batch_size) + 1
        local finish = start + x:size(1) - 1
        x:sub(1, x:size(1), i, i):copy(x_inp:sub(start, finish))
    end
    return x
end

local function load_data(fname)
    local data = file.read(fname)
    data = stringx.replace(data, '\n', '<eos>')
    data = stringx.split(data)
    --print(string.format("Loading %s, size of data = %d", fname, #data))
    local x = torch.zeros(#data)
    -- build dictionary vocab_map
    for i = 1, #data do
        if vocab_map[data[i]] == nil then
            vocab_idx = vocab_idx + 1
            vocab_map[data[i]] = vocab_idx
        end
        x[i] = vocab_map[data[i]]
    end
    return x
end

local function traindataset(batch_size, char)
   local x = load_data(trainfn)
   x = replicate(x, batch_size)
   return x
end

-- Intentionally we repeat dimensions without offseting.
-- Pass over this batch corresponds to the fully sequential processing.
local function testdataset(batch_size)
    if testfn then
        local x = load_data(testfn)
        x = x:resize(x:size(1), 1):expand(x:size(1), batch_size)
        return x
    end
end

local function validdataset(batch_size)
    local x = load_data(validfn)
    x = replicate(x, batch_size)
    return x
end

local function inverse_mapping()
   --[[
      create a inverse indexing for vocab_map
   ]]
    for w, i in pairs(vocab_map) do
       inv_vocab_map[i] = w
    end
end


-- members need to be returned in order to be called externally
return {traindataset=traindataset,
        testdataset=testdataset,
        validdataset=validdataset,
        inverse_mapping=inverse_mapping,
        vocab_map=vocab_map,
        inv_vocab_map=inv_vocab_map
     }
