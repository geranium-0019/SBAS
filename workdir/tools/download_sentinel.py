from data_downloader import downloader
import geopandas as gpd

def download_s1_slc(asf_file: str, folder_out: str, username: str, password: str):
    """
    Download Sentinel-1 SLC data from ASF using metadata geojson.

    Parameters
    ----------
    asf_file : str
        Path to ASF datapool results (geojson file).
    folder_out : str
        Directory to save the downloaded SLC data.
    username : str
        Earthdata login username.
    password : str
        Earthdata login password.
    """
    # 認証情報を登録
    netrc = downloader.Netrc()
    netrc.add('urs.earthdata.nasa.gov', username, password)

    # ASFメタデータ読み込み
    df_asf = gpd.read_file(asf_file)
    urls = df_asf.url

    # ダウンロード実行
    downloader.download_datas(urls, folder_out)
    print(f"✅ Download complete. Files saved to {folder_out}")
