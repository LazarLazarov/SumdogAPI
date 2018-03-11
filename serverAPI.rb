require "socket"
require "json"

server = TCPServer.new 4678


def createCorrectAns(min, max)
	correctHash = {}
 	while correctHash.empty?
	 	sum = rand(min..max)
	 	firstNum = rand(1..sum-1)

	 	# -- Check if a random value has been generated -- #
	 	if firstNum != nil
	 		secondNum = sum - firstNum
		 	if secondNum != 0
		 		correctHash = {"sum" => sum, "firstNum" => firstNum, "secondNum" => secondNum}
		 	end
		end
	 end
	 return correctHash
end


# error - how much to add or remove from the correct answer #
def createIncorrectAns(min, max, correctHash, nOfAnswers, error)
	incorrectHash = {}
 	while incorrectHash.length < nOfAnswers
 		incSum = -1
 		while incSum <= 0 || incSum == correctHash
 			incSum = correctHash + rand(-error..error)
 		end

	 	# -- Check for repeating answers -- #
	 	if !incorrectHash.has_value?(incSum)
			incorrectHash["incorrect" + incorrectHash.length.to_s] = incSum
		end
 	end
 	return incorrectHash
end


while session = server.accept
	flag = false
	request = session.gets
	puts request

	# -- Acquire range from URL parameters -- #
 	if request.split(" ")[1][1] == "?"
 		paramString = request.split('?')[1]     	# chop off the prefix
    	paramString = paramString.split(' ')[0] 	# chop off the HTTP version
    	paramArray  = paramString.split('&')    	# split parameters
    	if (paramArray.length == 2)					# check if only 2 parameters
    		flag = true
    		min = paramArray[0].split('=')[1]		# set min bound to first var
    		max = paramArray[1].split('=')[1]		# set max bound to second
    	end
 	end

 	# -- Convert range values from string to int -- #
 	min = min.to_i
 	max = max.to_i

 	# -- Make the range order invariant -- #
 	if (min > max)
 		min, max = max, min
 	end

 	# -- Check if range is valid -- #
 	if (!flag || min < 0 || max > 1000000 || 
 		(max == min && max == 0 || max == 1))
 		errorMsg = "Invalid range - range has to be between 0 and 1,000,000"
 		session.print "HTTP/1.1 500\r\n" +
					  "Content-Type: text/plain\r\n" +
					  "Content-Length: #{errorMsg.size}\r\n" +
					  "Connection: close\r\n" +
					  "\r\n"
		session.print errorMsg
 	else
	 	# -- Calculate the correct answer -- #
	 	answers = {}
	 	correctHash = createCorrectAns(min, max)
	 	answers["question"] = {"firstNum" => correctHash["firstNum"], "secondNum" => correctHash["secondNum"]}
	 	answers["answers"] = {"correct" => correctHash["sum"]}

	 	# -- Set the error for the incorrect answers -- #
	 	errorVal = max/10
	 	if (errorVal < 5) 
	 		errorVal = 5
	 	end

	 	# -- Calculate the incorrect answers and merge them with the correct answer -- #
	 	answers["answers"].merge!(createIncorrectAns(min, max, correctHash["sum"], 3, errorVal)) 

	 	# -- Send answers to client -- # 
		File.write('question.json', JSON.pretty_generate(answers))
		session.print "HTTP/1.1 200\r\n" +
					  "Content-Type: application/json\r\n" +
					  "Content-Length: #{File.size?("question.json")}\r\n" +
					  "Connection: close\r\n" +
					  "\r\n"
		IO.copy_stream('question.json', session)
	end
	session.close
end