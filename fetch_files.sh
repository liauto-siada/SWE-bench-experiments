#!/bin/bash

# 脚本：从ops2服务器获取evaluation文件
# 用法：./fetch_files.sh

# 设置变量
# REMOTE_HOST="ops1"
# REMOTE_BASE_PATH="/home/ops/agenthub_for_swebench/swe-bench/logs/run_evaluation/sympy_full_902/gold"

REMOTE_HOST="ops2"
# REMOTE_BASE_PATH="/home/ops/agenthub_for_swebench/swe-bench/logs/run_evaluation/django_full_902/gold"

# REMOTE_BASE_PATH="/home/ops/agenthub_for_swebench/swe-bench/logs/run_evaluation/other_full_903/gold"
REMOTE_BASE_PATH="/home/ops/agenthub_for_swebench/swe-bench/logs/run_evaluation/other_part_903/sympy"

LOCAL_BASE_PATH="/Users/caoxin/Projects/submit/SWE-bench-experiments/evaluation/lite/20250903_Siada_claude-4-sonnet/logs"

LOCAL_BASE_PATH_TRAJS="/Users/caoxin/Projects/submit/SWE-bench-experiments/evaluation/lite/20250903_Siada_claude-4-sonnet/trajs"

# 需要获取的文件列表
FILES_TO_FETCH=(
    "patch.diff"
    "report.json"
    "test_output.txt"
)

FILES_TO_FETCH_TRAJS=(
    "trace_test.json"
)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始从 $REMOTE_HOST 获取文件...${NC}"

# 检查本地目标目录是否存在，不存在则创建
if [ ! -d "$LOCAL_BASE_PATH" ]; then
    echo -e "${YELLOW}创建本地目录: $LOCAL_BASE_PATH${NC}"
    mkdir -p "$LOCAL_BASE_PATH"
fi

if [ ! -d "$LOCAL_BASE_PATH_TRAJS" ]; then
    echo -e "${YELLOW}创建本地轨迹目录: $LOCAL_BASE_PATH_TRAJS${NC}"
    mkdir -p "$LOCAL_BASE_PATH_TRAJS"
fi

# 首先获取远程目录下的所有子目录列表
echo -e "${YELLOW}获取远程目录列表...${NC}"

# 先检查远程路径是否存在
if ! ssh "$REMOTE_HOST" "test -d '$REMOTE_BASE_PATH'" 2>/dev/null; then
    echo -e "${RED}错误: 远程路径不存在或无法访问: $REMOTE_BASE_PATH${NC}"
    exit 1
fi

# 获取所有子目录
REMOTE_DIRS=$(ssh "$REMOTE_HOST" "ls -1 '$REMOTE_BASE_PATH'" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 无法连接到远程服务器${NC}"
    echo -e "${RED}请确保可以通过SSH连接到 $REMOTE_HOST${NC}"
    exit 1
fi

if [ -z "$REMOTE_DIRS" ]; then
    echo -e "${RED}警告: 远程目录为空或没有子目录${NC}"
    exit 1
fi

echo -e "${GREEN}找到以下子目录：${NC}"
echo "$REMOTE_DIRS" | while read -r dir; do
    echo "  - $dir"
done
echo ""

# 统计信息
TOTAL_DIRS=0
SUCCESS_DIRS=0
TOTAL_FILES=0
SUCCESS_FILES=0

# 将目录列表保存到临时文件，避免子shell问题
TEMP_FILE=$(mktemp)
echo "$REMOTE_DIRS" > "$TEMP_FILE"

# 计算总目录数
TOTAL_DIRS=$(wc -l < "$TEMP_FILE")

# 使用批量rsync来提高效率和可靠性
echo -e "${GREEN}使用批量rsync获取所有文件...${NC}"

# 创建rsync包含文件列表
INCLUDE_FILE=$(mktemp)
while IFS= read -r dir_name; do
    if [ -z "$dir_name" ]; then
        continue
    fi
    
    for file in "${FILES_TO_FETCH[@]}"; do
        echo "$dir_name/$file" >> "$INCLUDE_FILE"
    done
done < "$TEMP_FILE"

echo -e "${YELLOW}创建的包含文件列表包含 $(wc -l < "$INCLUDE_FILE") 个文件路径${NC}"

# 使用单个rsync命令获取所有文件
echo -e "${YELLOW}开始批量同步...${NC}"
if rsync -avz --progress --timeout=300 --include-from="$INCLUDE_FILE" --include='*/' --exclude='*' "$REMOTE_HOST:$REMOTE_BASE_PATH/" "$LOCAL_BASE_PATH/" 2>&1; then
    echo -e "${GREEN}✓ 批量同步完成${NC}"
else
    echo -e "${RED}✗ 批量同步失败，尝试逐个目录处理...${NC}"
    
    # 如果批量失败，回退到逐个处理
    PROCESSED_COUNT=0
    
    while IFS= read -r dir_name; do
        if [ -z "$dir_name" ]; then
            continue
        fi
        
        PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
        remote_dir="$REMOTE_BASE_PATH/$dir_name"
        local_dir="$LOCAL_BASE_PATH/$dir_name"
        
        echo -e "${YELLOW}处理目录 [$PROCESSED_COUNT/$TOTAL_DIRS]: $dir_name${NC}"
        
        # 创建本地对应目录
        mkdir -p "$local_dir" 2>/dev/null
        
        # 检查该目录下是否有我们需要的文件
        dir_has_files=false
        
        # 为当前目录创建文件列表
        DIR_INCLUDE_FILE=$(mktemp)
        for file in "${FILES_TO_FETCH[@]}"; do
            echo "$file" >> "$DIR_INCLUDE_FILE"
        done
        
        # 尝试同步当前目录
        if timeout 60 rsync -avz --timeout=30 --include-from="$DIR_INCLUDE_FILE" --exclude='*' "$REMOTE_HOST:$remote_dir/" "$local_dir/" >/dev/null 2>&1; then
            dir_has_files=true
            echo -e "  ${GREEN}✓ 目录同步成功: $dir_name${NC}"
        else
            echo -e "  ${RED}✗ 目录同步失败: $dir_name${NC}"
            rmdir "$local_dir" 2>/dev/null
        fi
        
        # 清理临时文件
        rm -f "$DIR_INCLUDE_FILE"
        
        # 每处理10个目录显示一次进度
        if [ $((PROCESSED_COUNT % 10)) -eq 0 ]; then
            echo -e "${GREEN}已处理 $PROCESSED_COUNT/$TOTAL_DIRS 个目录...${NC}"
        fi
        
    done < "$TEMP_FILE"
    
    echo -e "${GREEN}总共处理了 $PROCESSED_COUNT 个目录${NC}"
fi


# 清理临时文件
rm -f "$INCLUDE_FILE"

# ==================== 处理轨迹文件 ====================
echo -e "\n${GREEN}开始获取轨迹文件...${NC}"

# 创建轨迹文件的rsync包含列表
INCLUDE_TRAJS_FILE=$(mktemp)
echo "$REMOTE_DIRS" > "$TEMP_FILE"  # 重新创建临时文件

while IFS= read -r dir_name; do
    if [ -z "$dir_name" ]; then
        continue
    fi
    
    for file in "${FILES_TO_FETCH_TRAJS[@]}"; do
        echo "$dir_name/$file" >> "$INCLUDE_TRAJS_FILE"
    done
done < "$TEMP_FILE"

echo -e "${YELLOW}创建的轨迹文件列表包含 $(wc -l < "$INCLUDE_TRAJS_FILE") 个文件路径${NC}"

# 使用单个rsync命令获取所有轨迹文件
echo -e "${YELLOW}开始批量同步轨迹文件...${NC}"
if rsync -avz --progress --timeout=300 --include-from="$INCLUDE_TRAJS_FILE" --include='*/' --exclude='*' "$REMOTE_HOST:$REMOTE_BASE_PATH/" "$LOCAL_BASE_PATH_TRAJS/" 2>&1; then
    echo -e "${GREEN}✓ 轨迹文件批量同步完成${NC}"
    
    # 重命名 trace_test.json 为对应的 .traj 文件
    echo -e "${YELLOW}重命名轨迹文件...${NC}"
    RENAMED_COUNT=0
    
    while IFS= read -r dir_name; do
        if [ -z "$dir_name" ]; then
            continue
        fi
        
        source_file="$LOCAL_BASE_PATH_TRAJS/$dir_name/trace_test.json"
        target_file="$LOCAL_BASE_PATH_TRAJS/$dir_name.traj"
        
        if [ -f "$source_file" ]; then
            if mv "$source_file" "$target_file" 2>/dev/null; then
                echo -e "  ${GREEN}✓ 重命名: $LOCAL_BASE_PATH_TRAJS/trace_test.json -> $dir_name.traj${NC}"
                RENAMED_COUNT=$((RENAMED_COUNT + 1))
            else
                echo -e "  ${RED}✗ 重命名失败: $LOCAL_BASE_PATH_TRAJS/trace_test.json${NC}"
            fi
        fi
    done < "$TEMP_FILE"
    
    echo -e "${GREEN}成功重命名 $RENAMED_COUNT 个轨迹文件${NC}"
    
    # 删除空的子目录（只保留直接在trajs目录下的.traj文件）
    find "$LOCAL_BASE_PATH_TRAJS" -type d -empty -delete 2>/dev/null
    
else
    echo -e "${RED}✗ 轨迹文件批量同步失败${NC}"
fi

# 清理轨迹文件相关的临时文件
rm -f "$INCLUDE_TRAJS_FILE"

# 清理临时文件
rm -f "$TEMP_FILE"

# 计算最终统计信息
if [ -d "$LOCAL_BASE_PATH" ]; then
    SUCCESS_DIRS=$(find "$LOCAL_BASE_PATH" -mindepth 1 -maxdepth 1 -type d | wc -l)
    SUCCESS_FILES=$(find "$LOCAL_BASE_PATH" -type f | wc -l)
    TOTAL_FILES=$((TOTAL_DIRS * ${#FILES_TO_FETCH[@]}))
else
    SUCCESS_DIRS=0
    SUCCESS_FILES=0
    TOTAL_FILES=0
fi

# 计算轨迹文件统计信息
if [ -d "$LOCAL_BASE_PATH_TRAJS" ]; then
    SUCCESS_TRAJS_DIRS=$(find "$LOCAL_BASE_PATH_TRAJS" -mindepth 1 -maxdepth 1 -type d | wc -l)
    SUCCESS_TRAJS_FILES=$(find "$LOCAL_BASE_PATH_TRAJS" -name "*.traj" | wc -l)
    TOTAL_TRAJS_FILES=$((TOTAL_DIRS * ${#FILES_TO_FETCH_TRAJS[@]}))
else
    SUCCESS_TRAJS_DIRS=0
    SUCCESS_TRAJS_FILES=0
    TOTAL_TRAJS_FILES=0
fi

# 输出统计信息
echo -e "${GREEN}========== 获取完成 ==========${NC}"
echo -e "处理的目录数: $SUCCESS_DIRS/$TOTAL_DIRS"
echo -e "获取的文件数: $SUCCESS_FILES/$TOTAL_FILES"
echo -e "轨迹目录数: $SUCCESS_TRAJS_DIRS/$TOTAL_DIRS"
echo -e "轨迹文件数: $SUCCESS_TRAJS_FILES/$TOTAL_TRAJS_FILES"
echo -e "本地存储路径: $LOCAL_BASE_PATH"
echo -e "轨迹存储路径: $LOCAL_BASE_PATH_TRAJS"

# 显示获取到的文件结构
if [ $SUCCESS_FILES -gt 0 ]; then
    echo -e "\n${GREEN}获取到的评估文件结构:${NC}"
    find "$LOCAL_BASE_PATH" -type f | sort
else
    echo -e "\n${RED}没有成功获取任何评估文件${NC}"
fi

if [ $SUCCESS_TRAJS_FILES -gt 0 ]; then
    echo -e "\n${GREEN}获取到的轨迹文件结构:${NC}"
    find "$LOCAL_BASE_PATH_TRAJS" -name "*.traj" | sort
else
    echo -e "\n${RED}没有成功获取任何轨迹文件${NC}"
fi

echo -e "\n${GREEN}脚本执行完成！${NC}"
