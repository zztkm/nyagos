package history

import (
	"bufio"
	"bytes"
	"fmt"
	"os"
	"strconv"
	"strings"

	"../conio"
	"../interpreter"
)

func atoi_(reader *strings.Reader) (int, int) {
	n := 0
	count := 0
	for reader.Len() > 0 {
		ch, _, _ := reader.ReadRune()
		index := strings.IndexRune("0123456789", ch)
		if index >= 0 {
			n = n*10 + index
			count++
		} else {
			reader.UnreadRune()
			break
		}
	}
	return n, count
}

func Replace(line string) (string, bool) {
	var buffer bytes.Buffer
	isReplaced := false
	reader := strings.NewReader(line)
	history_count := len(conio.Histories)

	for reader.Len() > 0 {
		ch, _, _ := reader.ReadRune()
		if ch != '!' || reader.Len() <= 0 {
			buffer.WriteRune(ch)
			continue
		}
		ch, _, _ = reader.ReadRune()
		if n := strings.IndexRune("^$:*", ch); n >= 0 {
			reader.UnreadRune()
			if history_count >= 2 {
				insertHistory(&buffer, reader, history_count-2)
				isReplaced = true
			}
			continue
		}
		if ch == '!' { // !!
			if history_count >= 2 {
				insertHistory(&buffer, reader, history_count-2)
				isReplaced = true
				continue
			} else {
				buffer.WriteRune('!')
				continue
			}
		}
		if strings.IndexRune("0123456789", ch) >= 0 { // !n
			reader.UnreadRune()
			backno, _ := atoi_(reader)
			backno = backno % history_count
			if 0 <= backno && backno < history_count {
				insertHistory(&buffer, reader, backno)
				isReplaced = true
			}
			continue
		}
		if ch == '-' && reader.Len() > 0 { // !-n
			if number, count := atoi_(reader); count > 0 {
				backno := history_count - number - 1
				for backno < 0 {
					backno += history_count
				}
				if 0 <= backno && backno < history_count {
					insertHistory(&buffer, reader, backno)
					isReplaced = true
				} else {
					buffer.WriteString("!-0")
				}
				continue
			} else {
				reader.UnreadRune() // next char of '-'
			}
		}
		if ch == '?' { // !?str?
			var seekStrBuf bytes.Buffer
			lastCharIsQuestionMark := false
			for reader.Len() > 0 {
				ch, _, _ := reader.ReadRune()
				if ch == '?' {
					lastCharIsQuestionMark = true
					break
				}
				seekStrBuf.WriteRune(ch)
			}
			seekStr := seekStrBuf.String()
			found := false
			for i := history_count - 2; i >= 0; i-- {
				if strings.Contains(conio.Histories[i].Line, seekStr) {
					buffer.WriteString(conio.Histories[i].Line)
					isReplaced = true
					found = true
					break
				}
			}
			if !found {
				buffer.WriteRune('?')
				buffer.WriteString(seekStr)
				if lastCharIsQuestionMark {
					buffer.WriteRune('?')
				}
			}
			continue
		}
		// !str
		var seekStrBuf bytes.Buffer
		seekStrBuf.WriteRune(ch)
		for reader.Len() > 0 {
			ch, _, _ := reader.ReadRune()
			if ch == ' ' {
				reader.UnreadRune()
				break
			}
			seekStrBuf.WriteRune(ch)
		}
		seekStr := seekStrBuf.String()
		found := false
		for i := history_count - 2; i >= 0; i-- {
			if strings.HasPrefix(conio.Histories[i].Line, seekStr) {
				buffer.WriteString(conio.Histories[i].Line)
				isReplaced = true
				found = true
				break
			}
		}
		if !found {
			buffer.WriteRune('!')
			buffer.WriteRune(ch)
		}
	}
	result := conio.NewHistoryLine(buffer.String())
	if isReplaced {
		if history_count > 0 {
			conio.Histories[history_count-1] = result
		} else {
			conio.Histories = append(conio.Histories, result)
		}
	}
	return result.Line, isReplaced
}

func insertHistory(buffer *bytes.Buffer, reader *strings.Reader, historyNo int) {
	history1 := conio.Histories[historyNo]
	ch, siz, _ := reader.ReadRune()
	if siz > 0 && ch == '^' {
		if len(history1.Word) >= 2 {
			buffer.WriteString(history1.At(1))
		}
	} else if siz > 0 && ch == '$' {
		if len(history1.Word) >= 2 {
			buffer.WriteString(history1.At(-1))
		}
	} else if siz > 0 && ch == '*' {
		if len(history1.Word) >= 2 {
			buffer.WriteString(strings.Join(history1.Word[1:], " "))
		}
	} else if siz > 0 && ch == ':' {
		n, count := atoi_(reader)
		if count <= 0 {
			buffer.WriteRune(':')
		} else if n < len(history1.Word) {
			buffer.WriteString(history1.Word[n])
		}
	} else {
		if siz > 0 {
			reader.UnreadRune()
		}
		buffer.WriteString(history1.Line)
	}
}

func CmdHistory(cmd *interpreter.Interpreter) (interpreter.NextT, error) {
	var num int
	if len(cmd.Args) >= 2 {
		num64, err := strconv.ParseInt(cmd.Args[1], 0, 32)
		if err != nil {
			return interpreter.CONTINUE, err
		}
		num = int(num64)
	} else {
		num = 10
	}
	var start int
	if len(conio.Histories) > num {
		start = len(conio.Histories) - num
	} else {
		start = 0
	}
	for i, s := range conio.Histories[start:] {
		fmt.Fprintf(cmd.Stdout, "%3d : %-s\n", start+i, s.Line)
	}
	return interpreter.CONTINUE, nil
}

const max_histories = 2000

func Save(path string) error {
	var hist_ []*conio.HistoryLine
	if len(conio.Histories) > max_histories {
		hist_ = conio.Histories[(len(conio.Histories) - max_histories):]
	} else {
		hist_ = conio.Histories
	}
	fd, err := os.Create(path)
	if err != nil {
		return err
	}
	defer fd.Close()
	for _, s := range hist_ {
		fmt.Fprintln(fd, s.Line)
	}
	return nil
}

func Load(path string) error {
	fd, err := os.Open(path)
	if err != nil {
		return err
	}
	defer fd.Close()
	sc := bufio.NewScanner(fd)
	for sc.Scan() {
		conio.Histories = append(conio.Histories, conio.NewHistoryLine(sc.Text()))
	}
	return nil
}
