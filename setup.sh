#!/bin/bash

# ===============================================================
# Time Series InSAR - クイックセットアップスクリプト
# ===============================================================
# 
# ISCE2 + MintPy環境を簡単にセットアップするためのスクリプト
# 使用法: ./setup.sh
#
# ===============================================================

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ログ関数
log_info() { echo -e "${BLUE}ℹ [INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}✅ [SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠ [WARN]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}🔄 [STEP]${NC} $1"; }

# banner
show_banner() {
    echo -e "${CYAN}"
    echo "================================================================"
    echo "    Time Series InSAR - クイックセットアップ"
    echo "    ISCE2 + MintPy + Sentinel-1 Pipeline"
    echo "================================================================"
    echo -e "${NC}"
}

# 必須コマンドの確認
check_requirements() {
    log_step "必須コマンドの確認中..."
    
    local missing=()
    
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing+=("docker-compose または docker compose")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "以下のコマンドが見つかりません:"
        for cmd in "${missing[@]}"; do
            echo "  - $cmd"
        done
        echo
        echo "インストール方法:"
        echo "  Docker: https://docs.docker.com/get-docker/"
        echo "  Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    log_success "必須コマンドが確認できました"
}

# Dockerデーモンの確認
check_docker() {
    log_step "Docker環境の確認中..."
    
    if ! docker info &> /dev/null; then
        log_error "Dockerデーモンが起動していません"
        log_info "以下のコマンドでDockerを起動してください:"
        echo "  sudo systemctl start docker  # Linux"
        echo "  または Docker Desktopを起動  # Windows/Mac"
        exit 1
    fi
    
    log_success "Docker環境が利用可能です"
}

# .envファイルの設定
setup_env_file() {
    log_step ".envファイルの設定..."
    
    if [ ! -f .env ]; then
        log_info ".envファイルを作成中..."
        
        echo "# ===============================================" > .env
        echo "# 認証情報設定" >> .env
        echo "# ===============================================" >> .env
        echo "" >> .env
        echo "# NASA Earthdata 認証情報" >> .env
        echo "# https://urs.earthdata.nasa.gov/ でアカウント登録" >> .env
        echo "EARTHDATA_USER=your_username" >> .env
        echo "EARTHDATA_PASS=your_password" >> .env
        echo "" >> .env
        echo "# Copernicus Dataspace 認証情報 (オプション)" >> .env
        echo "# https://dataspace.copernicus.eu/" >> .env
        echo "CDSE_USER=your_cdse_username" >> .env
        echo "CDSE_PASS=your_cdse_password" >> .env
        echo "" >> .env
        
        log_success ".envファイルを作成しました"
        log_warn "EARTHDATA_USER と EARTHDATA_PASS を .env ファイルで設定してください"
        
        read -p "今すぐ .env ファイルを編集しますか? (y/N): " edit_env
        if [[ $edit_env =~ ^[Yy]$ ]]; then
            if command -v nano &> /dev/null; then
                nano .env
            elif command -v vim &> /dev/null; then
                vim .env
            else
                log_info ".env ファイルをお好みのエディタで編集してください："
                echo "  $(pwd)/.env"
            fi
        fi
    else
        log_success ".envファイルは既に存在します"
        
        # 設定チェック
        if grep -q "your_username" .env; then
            log_warn ".envファイルで認証情報を設定してください"
        fi
    fi
}

# ディレクトリ構造の作成
create_directories() {
    log_step "ディレクトリ構造を作成中..."
    
    local dirs=(
        "workdir/data/sentinel_images"
        "workdir/data/orbits"
        "workdir/data/aux"
        "workdir/data/dem"
        "workdir/processing/run"
        "workdir/processing/out"
        "workdir/logs"
        "workdir/tmp"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "作成: $dir"
        fi
    done
    
    log_success "ディレクトリ構造を作成しました"
}

# 設定ファイルテンプレートの作成
create_config_template() {
    log_step "設定ファイルテンプレートを作成中..."
    
    if [ ! -f workdir/config_template.yaml ]; then
        cat > workdir/config_template.yaml << 'EOF'
# ===============================================================
# Time Series InSAR 設定ファイル テンプレート
# ===============================================================
# 
# 使用法:
# 1. このファイルをコピー: cp config_template.yaml config_your_area.yaml
# 2. パスとパラメータを編集
# 3. スクリプト生成: python tools/gen_stack_scripts.py --config config_your_area.yaml
#
# ===============================================================

project:
  work_dir: /work/processing/run    # 作業フォルダ
  out_dir:  /work/processing/out    # 出力フォルダ

data:
  slc_dir:   /work/data/sentinel_images     # SLC (SAFE/zip)
  orbit_dir: /work/data/orbits              # 精密軌道 (-o)
  aux_dir:   /work/data/aux                 # AUX_EAP 等 (-a)
  dem:       /work/data/dem/dem.wgs84       # DEM (-d)

aoi:
  swath_num: "2"                            # サブスワス番号 (1,2,3 または "1 2 3")
  # bbox_snwe: [-6.46, -5.72, 106.43, 107.15]  # S N W E (必要時有効化)

coreg:
  method: NESD                              # 共役登録手法 (NESD/PS)
  reference_date: "20200302"                # 主画像日付 (YYYYMMDD)
  overlap_connections: 3                    # オーバーラップ接続数
  snr_misreg_threshold: 10                  # SNR誤登録閾値
  esd_coh_threshold: 0.85                   # ESD coherence閾値

ifgram:
  workflow: interferogram                   # ワークフロー (interferogram/offset)
  num_connections: 2                        # 時間接続数 (1=adjacent, 2=sparse)
  looks:
    range: 9                                # レンジルック数
    azimuth: 3                              # アジマスルック数
  filter_strength: 0.5                      # フィルタ強度 (0.0-1.0)

unwrap:
  method: snaphu                            # アンラッピング手法
  rm_filter: false                          # フィルタファイル削除

compute:
  use_gpu: false                            # GPU使用 (experimental)
  num_proc: 4                               # 並列プロセス数
  num_proc_topo: 2                          # topo並列プロセス数
  text_cmd: ""                              # 初期化コマンド (optional)

# ===============================================================
# 設定例:
#
# 小規模エリア（テスト用）:
#   num_connections: 1, num_proc: 2, range: 20, azimuth: 5
#
# 中規模エリア（標準）:
#   num_connections: 2, num_proc: 4, range: 9, azimuth: 3
#
# 大規模エリア（高精度）:
#   num_connections: 3, num_proc: 8, range: 3, azimuth: 1
# ===============================================================
EOF
        log_success "設定ファイルテンプレートを作成しました: workdir/config_template.yaml"
    else
        log_info "設定ファイルテンプレートは既に存在します"
    fi
}

# Docker環境の準備チェック
prepare_docker_env() {
    log_step "Docker環境の準備中..."
    
    # docker-compose.yml が存在するかチェック
    if [ ! -f .devcontainer/docker-compose.yml ]; then
        log_error ".devcontainer/docker-compose.yml が見つかりません"
        exit 1
    fi
    
    # イメージをビルド（初回のみ）
    log_info "Dockerイメージをビルド中... (初回は時間がかかります)"
    if command -v docker-compose &> /dev/null; then
        cd .devcontainer && docker-compose build && cd ..
    else
        cd .devcontainer && docker compose build && cd ..
    fi
    
    log_success "Docker環境が準備できました"
}

# 最終案内
show_usage() {
    echo
    echo -e "${WHITE}===============================================================${NC}"
    echo -e "${GREEN}🎉 セットアップが完了しました！${NC}"
    echo -e "${WHITE}===============================================================${NC}"
    echo
    echo -e "${CYAN}次の手順:${NC}"
    echo
    echo -e "${YELLOW}1. 認証情報の設定 (重要!)${NC}"
    echo "   .env ファイルで EARTHDATA_USER と EARTHDATA_PASS を設定"
    echo "   NASA Earthdata: https://urs.earthdata.nasa.gov/"
    echo
    echo -e "${YELLOW}2. 環境の起動${NC}"
    echo "   VS Code Dev Container を使用:"
    echo "     code ."
    echo "     Ctrl+Shift+P > Dev Containers: Reopen in Container"
    echo
    echo "   または直接Docker:"
    echo "     cd .devcontainer && docker-compose up -d"
    echo "     docker-compose exec mintpy-isce2 bash"
    echo
    echo -e "${YELLOW}3. Sentinel-1データのダウンロード${NC}"
    echo "   - ASF Data Search でデータ検索: https://search.asf.alaska.edu/"
    echo "   - geojsonファイルをダウンロード"
    echo "   - notebooks/download_sentinel-1.ipynb を実行"
    echo
    echo -e "${YELLOW}4. 設定ファイルの準備${NC}"
    echo "   cp workdir/config_template.yaml workdir/config_your_area.yaml"
    echo "   # config_your_area.yaml を編集"
    echo
    echo -e "${YELLOW}5. 処理実行${NC}"
    echo "   python workdir/tools/gen_stack_scripts.py --config workdir/config_your_area.yaml"
    echo "   ./workdir/run_stack.sh"
    echo
    echo -e "${GREEN}詳細はREADME.mdを参照してください${NC}"
    echo
    echo -e "${WHITE}===============================================================${NC}"
}

# メイン実行
main() {
    show_banner
    
    check_requirements
    check_docker
    setup_env_file
    create_directories
    create_config_template
    prepare_docker_env
    
    show_usage
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
